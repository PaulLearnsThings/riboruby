#!/usr/bin/ruby

puts "Please don't give me an empty string"; a = gets.chomp()

# We don't want to get an empty string, but don't force
# anything. Just print out the length.
puts ["The string that you gave me was empty? "] <<
						a.empty?

puts "Now an empty: "; a = gets.chomp
if !a.empty?
	puts "<Sarcastic output mode>"
	puts "Thanks for making sure you didn't give me something empty"
    puts "</Sarcastic output mode>"
end #Don't overdo the sarcasm too much, though
abort("Let's fail here, regardless.")

puts("Why... just why...")

puts("""There's literally no reason
	    that anyone should want to
	    try printing things *after*
	    we've aborted the program.""")

# We should never those print statements,
# since they occur after the program is aborted.


