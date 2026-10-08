while IFS= read -r server;do
	if [[ -n "$server" ]]; then
	       echo "Checking $server : " 
	       if ping -c 1 "$server";then
	       		echo "PASS"
		else
		       	echo "FAIL"
 		fi
	else 
		continue
	fi
done < servers.txt	
