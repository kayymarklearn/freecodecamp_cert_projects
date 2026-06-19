#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
declare -A unique_teams

while IFS=',' read -r year round winner opponent winner_goals opponent_goals; do
  # Skip header if present
  [[ "$year" == "year" ]] && continue

  unique_teams["$winner"]=1
  unique_teams["$opponent"]=1
done < games.csv

for team in "${!unique_teams[@]}"; do
  TEAM_EXISTS=$($PSQL "SELECT team_id FROM teams WHERE name='$team'")
  if [[ -z $TEAM_EXISTS ]]
  then
    INSERT_TEAM_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$team')")
    echo "Inserted into teams, $team"
  fi
done

while IFS=',' read -r year round winner opponent winner_goals opponent_goals; do
  [[ "$year" == "year" ]] && continue

  winner_id=$($PSQL "SELECT team_id FROM teams WHERE name='$winner'")
  opponent_id=$($PSQL "SELECT team_id FROM teams WHERE name='$opponent'")

  GAME_EXISTS=$($PSQL "SELECT game_id FROM games WHERE year=$year AND round='$round' AND winner_id=$winner_id AND opponent_id=$opponent_id")
  if [[ -z $GAME_EXISTS ]]
  then
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals)")
    echo "Inserted into games, $year $round: $winner vs $opponent"
  fi
done < games.csv
