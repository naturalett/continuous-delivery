url='http://localhost:9093/api/v1/alerts'
echo "Firing up alert"
curl -XPOST $url -d '[{"status": "firing","labels": {"alertname": "workshop"}}]'
echo ""

echo "press enter to resolve alert"
read

echo "sending resolve"
curl -XPOST $url -d '[{"status": "resolved","labels": {"alertname": "workshop"},"endsAt": "2020-07-23T01:05:38+00:00"}]'
echo ""

