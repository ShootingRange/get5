#!/bin/sh

export PATH="/usr/src/addons/sourcemod/scripting:$PATH"

python ./sm-builder/scripts/smbuilder --flags="-E"
