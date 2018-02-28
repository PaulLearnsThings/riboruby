#!/usr/bin/ruby

filename = ARGV[0]

# Make sure riboruby only runs on syntactically (if not semantically)
# valid scripts
result = `ruby -c #{filename}`
if !result.start_with?("Syntax OK")
	abort("Can't run riboruby on syntactically invalid Ruby script.")
end

# First, just grab all the lines of our script
lines = []
File.open(filename).each do |line|
  lines << line
end


def shortline?(line)
	line.length > 1 && line.length < 15
end

def mediumlongline?(line)
	line.length > 30  && line.length < 40
end

def longline?(line)
	line.length >= 40  && line.length < 60
end

def verylongline?(line)
	line.length >= 60;
end

# The mapping from physical features to conditionals is as follows:
#
# if:
#   long line
#   medium-long line
#   long line
#
# else:
#   medium-long line
#   long line
#   medium-long line
#
# elsif:
#   short line
#   very long line
#   short line
#
# end:
#   medium-long line
#   medium-long line
#   medium-long line
#   medium-long line
#
# Note that each chunk will only be converted if it's a potentially
# valid statement at that part. Thus, an else/elsif/end won't be
# translated if a valid if hasn't been found, and an elsif won't appear
# after a catch-all else.
#
#
#

def isIfStatement(lines, index)
	return longline?(lines[index])  &&
		   mediumlongline?(lines[index + 1])  &&
		   longline?(lines[index + 2])
end

def isElseStatement(lines, index)
	return mediumlongline?(lines[index])  &&
		   longline?(lines[index + 1])  &&
		   mediumlongline?(lines[index + 2])
end

def isElsifStatement(lines, index)
	return shortline?(lines[index])  &&
		   verylongline?(lines[index + 1])  &&
		   shortline?(lines[index + 2])
end

def isEndStatement(lines, index)
	return mediumlongline?(lines[index])  &&
		   mediumlongline?(lines[index + 1])  &&
		   mediumlongline?(lines[index + 2])  &&
		   mediumlongline?(lines[index + 3])
end

def isThenStatement(lines, index)
	return mediumlongline?(lines[index])  &&
		   shortline?(lines[index + 1])  &&
		   mediumlongline?(lines[index + 2])		   
end

# Mappings from line chunks that have some conditional feature to
# the feature they represent
# e.g. [[32, 33, 34], 'IF']
statementChunks = []

# Chunks which have been confirmed to have matching conditionals and
# are able to be replaced in the code.
# e.g. [[34, 35, 36], 'IF']
chunksToReplace = []

# Handle the chunking of every line
def handleLine(lines, index, statementChunks)
	if isIfStatement(lines, index)
		statementChunks << [[index, index+1, index+2], 'IF']
	elsif isElseStatement(lines, index)
		statementChunks << [[index, index+1, index+2], 'ELSE']
	elsif isElsifStatement(lines, index)
		statementChunks << [[index, index+1, index+2], 'ELSIF']
	elsif isThenStatement(lines, index)
		statementChunks << [[index, index+1, index+2], 'THEN']
	elsif isEndStatement(lines, index)
		statementChunks << [[index, index+1, index+2, index+3], 'END']

	end
end

# See which chunks are "features" that we should match to conditional
# phrases
def evaluateReplaceableChunks(statementChunks, chunksToReplace)
	endChunkIndex = statementChunks.index { |item|
		item[1] == 'END'
	}
	
	while endChunkIndex != nil	
		closestIfIndex = statementChunks.slice(0, endChunkIndex + 1).reverse.index { |item|
			item[1] == 'IF'
		}
		
		if closestIfIndex == nil
			closestIfIndex = 0
		else
			# We got the index of the reversed list: re-reverse it
			closestIfIndex = statementChunks.slice(0, endChunkIndex + 1).length - closestIfIndex - 1
			lastThingWasIf = true

			chunksToReplace << [statementChunks[closestIfIndex][0], 'IF']
			chunksToReplace << [statementChunks[endChunkIndex][0], 'END']

			hitElse = false
			(closestIfIndex...endChunkIndex).each { |innerIndex|
				chunkType = statementChunks[innerIndex][1]
				if chunkType == 'ELSE' and !hitElse
					hitElse = true
					lastThingWasIf = false
					chunksToReplace << [statementChunks[innerIndex][0], 'ELSE']
				elsif chunkType == 'ELSIF' and !hitElse
					chunksToReplace << [statementChunks[innerIndex][0], 'ELSIF']					
					lastThingWasIf = true
				elsif chunkType == 'THEN' and lastThingWasIf
					chunksToReplace << [statementChunks[innerIndex][0], 'THEN']					
					lastThingWasIf = false
				
				end
			}
		end
		
		statementChunks.slice!(closestIfIndex, endChunkIndex + 1)
		
		endChunkIndex = statementChunks.index { |item|
			item[1] == 'END'
		}
	end
end

# Once we know which chunks we can safely replace, go ahead and replace
# them
def replaceChunks(chunksToReplace, lines)
	chunksToReplace.each { |chunk, value| 
		if value == 'IF'
			lines[chunk[0]] = "if"
			lines[chunk[1]] = "("
			lines[chunk[2]] = ""
		elsif value == 'ELSE'
			lines[chunk[0]] = ")"
			lines[chunk[1]] = "else"
			lines[chunk[2]] = "("
		elsif value == 'ELSIF'
			lines[chunk[0]] = ")"
			lines[chunk[1]] = "elsif"
			lines[chunk[2]] = "("
		elsif value == 'THEN'
			lines[chunk[0]] = ")"
			lines[chunk[1]] = "then"
			lines[chunk[2]] = "("
		elsif value == 'END'
			lines[chunk[0]] = ")"
			lines[chunk[1]] = "end"
			lines[chunk[2]] = ""
			lines[chunk[3]] = ""

		else
			abort("Got unsupported chunk type: #{value}")
		end
	}
end

# Evaluate chunks up until there are no four-chunks left (even if
# the last three chunk is a block, it won't produce a valid program
# without an associated end block)
(0...lines.length - 4).each do |i|
	# If we already included this line in a prevous chunk, don't include
	# it again
	if !statementChunks.empty? && statementChunks.last[0].include?(i)
		next
	end
	
	handleLine(lines, i, statementChunks)
end

evaluateReplaceableChunks(statementChunks, chunksToReplace)

replaceChunks(chunksToReplace, lines)
puts lines
