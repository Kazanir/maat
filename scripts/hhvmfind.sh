#!/bin/bash

ps ax | grep 'hhvm -m server' | grep -v grep | awk '{print $1}'
