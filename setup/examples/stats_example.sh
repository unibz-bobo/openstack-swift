#!/bin/bash

source "$(dirname $0)/examples_configuration.sh"

swift -A $URL_AUTHENTICATION -U $USER_AUTHENTICATION -K $KEY_AUTHENTICATION stat
