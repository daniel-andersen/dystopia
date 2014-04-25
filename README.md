Dystopia
========

Dystopia is an interactive, digital tabletop board game based on the board game [Kampen mod Dystopia (Danish)](http://trollsahead.dk/dystopia/index.html). It combines interaction between physical bricks and a digital board projected from a mini projector connected to an iPhone.

The project combines several interesting techniques, including computer vision, artificial intelligence and game engine design.

See photos and videos below.

Description
-----------

Dystopia itself is an iPhone app which - when run on an iPhone connected to a simple projector setup - creates an interactive, digital tabletop board game playable on any table.

By monitoring the projected board game from the camera of the iPhone, the app recognizes the board state by detecting the positions of the physical bricks. By interacting with the bricks the state changes and the board game evolves (eg. new rooms are revealed, monsters appear, etc.).

The app also functions as Game Master by marking the movements of the monsters, deciding the outcome of fights, etc.

The setup
---------

What you need in order to getting started:

* An iPhone (>= 5?)
* A mini projector (not pico, as the resolution should be at least 1280x800, and depending on the setup, not full size because of the weight)
* A Lightning to VGA adapter to connect the iPhone to the projector
* A camera stand with a cross bar capable of fitting a projector and an iPhone above a table. (I did my own from an unused clothing rack; see photos below)
* Bricks with black feet (see photos below)
* A table :-)

Getting started
---------------

Simple enough:

Install the app, plug in the projector and the iPhone in the stand; connect the iPhone to the projector and start the app. As soon as the app recognizes the board on the table it will place markers for the heroes in the starting room. Now place a brick on a hero marker. A red circle will appear as soon as the brick has been recognized.

Or, you can simply run the app from the iPhone simulator and click any piece on the board to simulate a brick placement.

Current state
-------------

The following features have been implemented:

* Board recognition
* Brick recognition
* Detection of brick movements
* Reveiling of new rooms
* Simple turn based game engine

What's up next?
---------------

* Simple AI to control monsters
* More advanced game mechanics, like fights
* Methods for players to make descisions not only by moving bricks

See the issue list for further info.

Articles
--------

[Article in Prosabladet (Danish)](https://www.prosa.dk/fileadmin/user_upload/dokumenter/PROSAbladet/2014/Prosabladet_April_2014_web.pdf)

Videos
------

[Dystopia - opening doors](http://youtu.be/q70jRrMF240)

[Dystopia - brick movement](http://youtu.be/2pPu2RXxLaE)

[Dystopia - brick recognition](http://youtu.be/lE4cS93vqYw)

Photos
------

All photos are copyright by Henrik Bengtsson.

![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/1.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/2.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/3.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/4.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/5.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/6.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/7.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/8.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/9.jpg "Dystopia Image")
![alt text](https://raw.githubusercontent.com/black-knight/dystopia/master/photos/10.jpg "Dystopia Image")

