#!/bin/env bash

echo() ( 
  IFS=" " 
  printf '%s\n' "$*"
)

echo_n() (
  IFS=" "
  printf %s "$*"
)

echo_e() (
  IFS=" "
  printf '%b\n' "$*"
)
