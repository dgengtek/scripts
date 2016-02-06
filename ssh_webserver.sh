#!/bin/bash
path="/home/gd/.ssh/id_rsa_home"
fingerprint=$(ssh-keygen -lf "$path"  | awk '{print $2}')
ssh-add -l | grep -q "$fingerprint" || ssh-add "$path"
ssh gd@192.168.0.6
