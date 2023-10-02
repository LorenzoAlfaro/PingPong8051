# Ping Pong 8051

### Introduction.

Welcome! For some crazy reason you are reading about a project based on Intel's Microcontroller 8051, relesead in the year of our Lord 1980. I guess some people just like old techy stuff, eh?

The purpose of this repository is to preserve the work I created during a college course taken in 2012. I was supposed to build a minimum system that did something useful.

Being the gamer that I am decided I to build a ping pong game... in assembly language... ouch!


### The Hardware side of things.

The project was built a round an LED matrix which was custom made. (My partner built it so he got to keep it). Lots of soldering LEDs. You can see these very low res video I took and a picture I took of it.

![image](https://github.com/LorenzoAlfaro/PingPong8051/assets/58958983/bbc16b82-e918-4b55-9e0e-91d0cf85be8e)


https://www.youtube.com/watch?v=GOFcKyjivUg

The 8051 is configured in external memory mode. The LED matrix was interfaced using a PPI (8255) to expand the number of outputs in the 8051.

## Software.

Written in Assembly. I still need to create a standard for the code to improve readability and maintainability.

I'm trying to use VS Code to write the code, but I have conflicting formatting options with **8051 MCU IDE**. Tabs are 4 spaces.


### Current state

Having enjoyed working on this project, I feel it a shame not to document it and even enhance it. While working on cleaning up the code I realized something. I got it to work then but, did a terribly job in writting maintainable code. Many things in the original version of the software were written in a haphazardly manner. So I started the refactoring by removing hard coded values for the dimmension of the matrix. Also separating the code into re-usable macros.


Even though I don't have the original hardware, I found a way to simulate it. The downside is that the simulated matrix is only 8x8. So the project has lost its glorious 15x15 resolution. And the simulation speed is very slow.



Simulated version 8x8

![Ping Pong Sim (1)](https://github.com/LorenzoAlfaro/PingPong8051/assets/58958983/9e9e238b-8e45-4686-a2f6-0415ea7bc673)



![image](https://github.com/LorenzoAlfaro/PingPong8051/assets/58958983/4ed4e585-c67f-4e19-9003-c66fa2186036)

![image](https://github.com/LorenzoAlfaro/PingPong8051/assets/58958983/c09a7d3f-c6da-4842-9f58-ac4287382c8f)


