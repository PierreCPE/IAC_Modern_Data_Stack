import streamlit as st
import snowflake.connector
import pandas as pd

# Connexion à Snowflake
def get_data_from_snowflake():
    conn = snowflake.connector.connect(
        user="YOUR_USER",
        password="YOUR_PASSWORD",
        account="YOUR_ACCOUNT"
    )
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users;")
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    df = pd.DataFrame(rows, columns=columns)
    cursor.close()
    conn.close()
    return df

# Streamlit App
st.title("Visualisation des données utilisateurs")
df = get_data_from_snowflake()
st.write(df)