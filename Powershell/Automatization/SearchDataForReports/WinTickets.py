# encoding=utf8
import psycopg2
import pymssql
from psycopg2.extras import DictCursor
from datetime import datetime
import os
def get_postgres_data():
    pg_params = {"host": "YourBdNAME.db.osmp.ru", "database": "YourBdNAME", "user": "ACCOUNT", "password": "************", "port": "5432", "client_encoding": 'UTF8'}
    query = """
    SELECT 
        ji.pkey,
        COALESCE(
            cu_from_cwd.display_name,
            cu_from_app.display_name,
            ji.assignee
        ) AS assignee,
        it.pname AS issuetype,
        r.pname AS resolution,
        ji.created,
        ji.resolutiondate,
        ji.updated,
        ji.summary
    FROM 
        YourBdNAME.YourBdNAMEissue ji
    LEFT JOIN 
        YourBdNAME.issuetype it ON ji.issuetype = it.id
    LEFT JOIN 
        YourBdNAME.resolution r ON ji.resolution = r.id
    LEFT JOIN 
        YourBdNAME.cwd_user cu_from_cwd ON ji.assignee = cu_from_cwd.user_name
    LEFT JOIN 
        YourBdNAME.app_user au ON ji.assignee = au.user_key
    LEFT JOIN 
        YourBdNAME.cwd_user cu_from_app ON au.lower_user_name = cu_from_app.lower_user_name
    WHERE 
        (ji.pkey LIKE 'PROJECT-%' OR ji.pkey LIKE 'PROJECT-%' OR ji.pkey LIKE 'PROJECT-%')
        AND ji.created >= '2024-01-01 00:00:00'
        AND ji.resolution IS NOT NULL;
    """

    try:
        conn = psycopg2.connect(**pg_params)
        cursor = conn.cursor(cursor_factory=DictCursor)
        cursor.execute(query)
        return cursor.fetchall()
    except Exception as e:
        #print(f"PostgreSQL error: {e}")
        print("PostgreSQL error: {}".format(e))
        return None
    finally:
        if 'conn' in locals():
            cursor.close()
            conn.close()

def write_log(status, new_values_count, error_message=None):
    """YourBdNAMEA"""
    try:
        conn = pymssql.connect('YOURBDHOSTNAME', 'LoginForConnect', '**********', 'reportTest')
        cursor = conn.cursor()
        log_query = """
        INSERT INTO YourBdNAMEA (
            Status, NewValuesCount, Date
        ) VALUES (%s, %s, %s)
        """
        cursor.execute(log_query, (
            status[:255],
            new_values_count,
            datetime.now()
        ))
        conn.commit()
    except Exception as e:
        #print(f"Error writing to log: {e}")
        print("Error writing to log: {}".format(e))
    finally:
        if 'conn' in locals():
            conn.close()
def insert_to_sqlserver(data):
    if not data:
        print("No data to insert")
        write_log("Error", 0, "No data received from PostgreSQL")
        return
    try:
        conn = pymssql.connect('YOURBDHOSTNAME', 'LoginForConnect', '************', 'reportTest')
        cursor = conn.cursor()
        cursor.execute("SELECT pkey FROM YourBdNAME")
        existing_pkeys = {row[0] for row in cursor.fetchall()}

        insert_query = """
        INSERT INTO YourBdNAME (
            pkey, assignee, issuetype, resolution, 
            summary, created, resolutiondate, updated
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """

        inserted_count = 0
        skipped_count = 0
        error_occurred = False
        last_error = None

        for row in data:
            pkey = row['pkey'][:255] if row['pkey'] else ''
            
            if pkey in existing_pkeys:
                skipped_count += 1
                continue

            try:
                cursor.execute(insert_query, (
                    pkey,
                    str(row['assignee'])[:255] if row['assignee'] else '',
                    str(row['issuetype'])[:255] if row['issuetype'] else '',
                    str(row['resolution'])[:255] if row['resolution'] else '',
                    str(row['summary'])[:255] if row['summary'] else '',
                    row['created'],
                    row['resolutiondate'],
                    row['updated']
                ))
                conn.commit()
                existing_pkeys.add(pkey)
                inserted_count += 1
            except Exception as e:
                error_occurred = True
                last_error = str(e)
                conn.rollback()
                #print(f"Error inserting row {pkey}: {e}")
                print("Error inserting row {}: {}".format(pkey, e))

        #print(f"Inserted: {inserted_count}, Skipped (duplicates): {skipped_count}")
        print("Inserted: {}, Skipped (duplicates): {}".format(inserted_count, skipped_count))
        if error_occurred:
            #write_log("Partial Success", inserted_count, f"Errors occurred. Last error: {last_error}")
            write_log( "Partial Success", inserted_count, "Errors occurred. Last error: {}".format(last_error))
        else:
            write_log("Success", inserted_count)
            
    except Exception as e:
        #print(f"SQL Server error: {e}")
        print("SQL Server error: {}".format(e))
        write_log("Error", 0, str(e))
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    #print(f"Script started at {datetime.now()}")
    data = get_postgres_data()
    
    if data:
        #print(f"Retrieved {len(data)} records from PostgreSQL")
        print("Retrieved {} records from PostgreSQL".format(len(data)))
        insert_to_sqlserver(data)
    else:
        print("No data retrieved from PostgreSQL")
        write_log("Error", 0, "No data retrieved from PostgreSQL")
    
    #print(f"Script finished at {datetime.now()}")