#!/bin/bash
# mycollate.sh <database> [<charset> <collation>]
# changes MySQL/MariaDB charset and collation for one database - all tables and
# all columns in all tables

DB="$1"
CHARSET="$2"
COLL="$3"

[ -n "$DB" ] || echo "no database selected" exit 1

[ -n "$CHARSET" ] || CHARSET="utf8mb4"
[ -n "$COLL" ] || COLL="utf8mb4_general_ci"

read -s -p 'Enter Password: ' PASSWORD
[ -z "$PASSWORD" ] ||  PASSWORD="-p"$PASSWORD

echo "sets autocommit, unique_checks and foreign_key_checks to 0"
echo "SET autocommit=0; SET UNIQUE_CHECKS=0; SET foreign_key_checks=0;" | mysql $PASSWORD

echo "convert database $DB"
# echo "ALTER DATABASE $DB CHARACTER SET $CHARSET COLLATE $COLL;" | mysql $PASSWORD

echo "convert tables"
echo "SELECT CONCAT('ALTER TABLE ', TABLE_SCHEMA, '.', TABLE_NAME,' CONVERT TO CHARACTER SET $CHARSET COLLATE $COLL;') AS ExecuteTheString FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_COLLATION NOT IN ('$COLL');" | mysql -s $PASSWORD $DB | ( while read EXECUTESTRING; do
        echo "$EXECUTESTRING"
#        echo "$EXECUTESTRING" | mysql $PASSWORD $DB
    done
)
echo "convert columns"
echo "SELECT concat('ALTER TABLE ', t1.TABLE_SCHEMA, '.', t1.table_name, ' MODIFY ', t1.column_name, ' ', t1.data_type, '(' , CHARACTER_MAXIMUM_LENGTH, ')', ' CHARACTER SET $CHARSET COLLATE $COLL;' ) as stringToExecute from information_schema.columns t1 where t1.COLLATION_NAME IS NOT NULL AND t1.TABLE_SCHEMA = '$DB' AND t1.COLLATION_NAME NOT IN ('$COLL');" | mysql -s $PASSWORD $DB | (while read EXECUTESTRING; do
        EXECUTESTRING=$(echo $EXECUTESTRING | sed 's/longtext\(.*\)/longtext/g' | sed 's/mediumtext\(.*\)/mediumtext/g')
        echo "$EXECUTESTRING"
 #       echo "$EXECUTESTRING" | mysql $PASSWORD $DB
    done
)
echo "sets autocommit, unique_checks and foreign_key_checks to 1"
echo "SET FOREIGN_KEY_CHECKS=1; SET UNIQUE_CHECKS=1; SET autocommit=1;" | mysql $PASSWORD
