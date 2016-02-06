#!/bin/bash
path="/home/gd/.ssh/id_rsa_vcs"
fingerprint=$(ssh-keygen -lf "$path"  | awk '{print $2}')
ssh-add -l |grep -q "$fingerprint" || ssh-add "$path"
