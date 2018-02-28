# Riboruby

In biology, there are neat structures within bacteria called Riboswitches. Riboswitches are physical features (e.g. loops, U-turns, twirls) that allow other chemicals to bind onto the RNA strands and *change* the way in which the RNA code is evaluated or translated into proteins.

In essence, the *shape* of the RNA code impacts the *control flow* of the code.

Riboruby is an attempt to emulate this concept within Ruby codebases: physical features of the code (based on line length) will be used to define control-flow conditions (if, then, else, elsif, end) within a Ruby script.

The vast majority of scripts (basically all scripts tested so far) don't actually yield useful results, or just fail to run at all. But maybe, just maybe, some neat emergent behavior can come out of this down the line. If not, the silliness and absurdity will have to be enough!

## Test Data
Included is a sample Ruby script `test-ruby-script.rb`, along with the Riboruby-ized script we get by feeding that test script into Riboruby: `riborubyized-test-ruby-script.rb`. Note that both execute, but certain line-length features are removed entirely and replaced be control flow structures post-Riboruby.
