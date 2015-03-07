#!/bin/bash

source examples_configuration.sh

swift -A $URL_AUTHENTICATION -U $USER_AUTHENTICATION -K $KEY_AUTHENTICATION stat
