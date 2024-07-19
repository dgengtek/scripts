#!/usr/bin/env bash

main() {
	local -r n_times=${1:-3}
	local -r interval=${2:-3}
	shift 2
	trap "trap - SIGINT;exit 128;" SIGINT
	let count=1
	while ! $@; do
		if (($count == 3)); then
			break
		fi
		sleep $interval
		let count+=1
	done
	trap - SIGINT
}
main "$@"
