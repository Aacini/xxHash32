**What these files are and where they comes from?**

I started to studied hash functions because I need to process a huge file in which it is necessary to search for a certain string. The job of keeping such a large file sorted so that a binary search can be performed on it was out of the question. Instead, I thought about creating a companion file with only two fields per record, the 32-bit hash value and the position (32-bit offset) of each record in the original file, so this much smaller file could be kept sorted more easily. Of course, multiple collisions need to be managed.

I needed a simple and fast hash function. I asked Google Gemini and ChaptGPT and they suggested xxHash, so I selected the xxHash 32-bit flavor for my needs. I reviewed the original xxh32 C++ code and found it to be somewhat confusing, so I wrote my own pure C version that I hope be clearer and simpler. I then translated this code into a highly optimized **xxh32.asm** MASM32 assembler version that I'm pretty sure will outperform the original code or any other equivalent C or C++ code (although I haven't had time to complete some timing tests).

I then thought that these hashes might also be useful to other users, so I extended my xxh32 function to a complete Windows console program that generates 32-bit hashes from strings supplied in several different forms. The resulting **xxHash32.asm** program and its **xxHash32.exe** executable version are also included here.

One option of my program allows to generate the hashes of all the lines in an input file, so I devised to collect the 32-bit hashes in a long "string" and take the xxHash32 from they all. The result is a new 32-bit hash value (I could nickname it "xxh32-squared" as a joke) that can be used to check the integrity of a simple text file when no more requirements are needed.

After that, I wondered if this method could be translated to a Windows Batch file... The technical challenge was interesting because the original code uses several unsigned operations which are not available in the cmd.exe's SET /A command. I had a lot of fun trying to compensate for the inherent limitations of Batch files in a way that was not only functional, but also looked like the original. I finally resolved all the issues and the batch file **xxHash32.bat** is also included here.

I suspect this Batch version is the slowest one of all different versions published here (after the Bash one). If so, then _the fastest and the slowest_ xxh32 versions are mine!  **;)**
