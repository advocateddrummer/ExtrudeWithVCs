Extrude with Volume Conditions
==============================

This Pointwise Glyph script serves a very specific purpose: to create extruded
structured blocks from selected structured domains while automatically giving
each extruded block a unique volume condition. The unique volume condition is
extracted from preexisting boundary conditions belonging to the structured
domains used for the extrusion.

**Note:** The script currently only supports extrusion of structured domains
along a path.

I have used this to make a LARGE number of extruded blocks that each needed
unique volume tags automatically, repeatedly, and quickly.

Usage
-----

This script may be run on pre-selected domains or, if upon execution there are
no domains selected, the script will prompt the user to select the desired
domains. The script then prompts the user to specify which connector will be
used to define the extrusion path.

The structured domains must all have boundary conditions applied that match a
certain pattern; the pattern may be tweaked by adjusting the regular expression
in the script. Currently an acceptable pattern is 'foo1\_0'. The script will
extract this boundary condition and create the volume tag 'foo1\_1' by
incrementing the number after the underscore.

One sort of hacky aspect of this script is that it applies the same volume tag
name to all of the newly created domains of the extruded block as a boundary
condition. This is to make it easy to run the script over and over again on the
advancing front of the extrusions. I.e. to make a large stack of extruded
blocks.
