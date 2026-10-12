environment="development"
app="api"

while getopts ":e:a:h" option; do
	case "$option" in
		e) 
			environment="$OPTARG"
			;;
		a)
			app="$OPTARG"
			;;
		h)
			echo "Usage: $0 [-e environment] [-a application] [-h]"
			exit 0
			;;
		:)
			echo "Option -$OPTARG requires a value" >&2
			exit 2
			;;
		\?)
			echo "Unknown option: -$OPTARG" >&2
			exit 2
			;;
	esac
done

echo "App: $app | Environment: $environment"
