#!/bin/bash
find Dystopia -name "*.m" | xargs grep -L "Copyright (c) 2013, Daniel Andersen (daniel@trollsahead.dk)"
find Dystopia -name "*.h" | xargs grep -L "Copyright (c) 2013, Daniel Andersen (daniel@trollsahead.dk)"

