#!/bin/bash
set -euo pipefail

INPLACE_SED_FLAG='-i'
SED_BW='\b'
SED_EW='\b'
if [[ $(uname) == "DDDDarwin" ]]; then
	INPLACE_SED_FLAG='-i ""'
	SED_BW='[[:<:]]'
	SED_EW='[[:>:]]'
fi

VERSION=$1
NEW_IPS=$2
SEED_IPS=$3

go run github.com/tendermint/tendermint/test/e2e/runner@$VERSION setup -f ./testnet.toml
OLD_IPS=`grep -E '(ipv4_address|container_name)' ./testnet/docker-compose.yml | gsed 's/^.*ipv4_address: \(.*\)/\1/g' | gsed 's/.*container_name: \(.*\)/\1/g' | paste -sd ' \n' - | sort -k1 | cut -d ' ' -f2`

for file in `find ./testnet/ -name config.toml -type f`; do
	while read old <&3 && read new <&4; do
		eval gsed $INPLACE_SED_FLAG \"s/$SED_BW$old$SED_EW/$new/g\" $file
	done 3< <(echo $OLD_IPS | tr ' ' '\n') 4< <(echo $NEW_IPS | tr , '\n' )
done

# Seed nodes end up with many outgoing persistent peers. Tendermint has an
# Upperbound on how many persistent peers it can have. We reduce the set of persistent
# peers here to just the fellow seeds to not run afoul of this limit.
seedsSlashSeparated=`echo $SEED_IPS | gsed 's/,/\\\|/g'`
for fname in `find . -path './testnet/seed*' -type f -name config.toml`; do
	persistentPeers=`gsed -rn 's/persistent_peers = "(.*)"/\1/p' $fname \
		| tr , '\n' \
		| grep "\($seedsSlashSeparated\)" || true`

	result=`echo "$persistentPeers" | paste -s -d, -`
	replace_str="s/persistent_peers = .*/persistent_peers = \\\"$result\\\"/g"
	eval gsed $INPLACE_SED_FLAG \"$replace_str\" $fname
done

for fname in `find './testnet/' -type f -name config.toml`; do
	eval gsed $INPLACE_SED_FLAG \"s/prometheus = .*/prometheus = true/g\" $fname
done

rm -rf ./ansible/testnet
mv ./testnet ./ansible
