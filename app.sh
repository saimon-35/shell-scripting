action="${1:-status}"
case "$action" in
	start)
		echo "Starting application..."
		;;
	stop)
		echo "Stopping application..."
		;;
	restart)
		echo "Restarting application..."
		;;
	status)
		echo "Checking status"
		;;
	*)
		echo "Usage: $0 {start|stop|restart|status}">&2
		exit 2
		;;
esac
