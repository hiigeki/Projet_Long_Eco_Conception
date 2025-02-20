#!/bin/bash

# Vérifier que l'utilisateur a fourni une durée
if [ -z "$1" ]; then
    echo "Usage: $0 <durée en secondes>"
    exit 1
fi

DURATION=$1
INTERVAL=100  # Intervalle entre les mesures en milisecondes
INTERVAL_FLOAT=$(echo "scale=2; $INTERVAL / 1000" | bc -l)
SUM=0
COUNT=0
DATA_FILE="power_data.txt"
echo "Temps (s) Consommation (W)" > $DATA_FILE

# Fonction pour récupérer la consommation instantanée
get_power() {
    cat /sys/class/power_supply/BAT0/current_now /sys/class/power_supply/BAT0/voltage_now | xargs | awk '{print $1 * $2 / 1e12}'
}

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))
CURRENT_TIME=0

while [ $(date +%s) -lt $END_TIME ]; do
    POWER=$(get_power)
    SUM=$(echo "$SUM + $POWER" | bc)
    COUNT=$((COUNT + 1))
    echo "$CURRENT_TIME $POWER" >> $DATA_FILE
    sleep $INTERVAL_FLOAT
    CURRENT_TIME=$((CURRENT_TIME + 10))
done

# Calcul de la consommation moyenne
if [ $COUNT -gt 0 ]; then
    AVG_POWER=$(echo "$SUM / $COUNT" | bc -l)
    echo "Consommation électrique moyenne sur $DURATION secondes: $AVG_POWER W"
else
    echo "Aucune mesure effectuée."
fi

# Générer un graphique avec gnuplot
gnuplot -e "set terminal png size 800,600; \
set output 'power_graph.png'; \
set title 'Consommation électrique'; \
set xlabel 'Temps (ms)'; \
set ylabel 'Consommation (W)'; \
set datafile separator ' '; \
plot '< tail -n +2 power_data.txt' using 1:2 with lines title 'Puissance'"

echo "Graphique généré : power_graph.png"