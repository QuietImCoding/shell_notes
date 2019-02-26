import sqlite3

def getCursorFromFile(f):
    global conn
    global cur
    conn = sqlite3.connect(f, check_same_thread=False)
    cur = conn.cursor()

def execQuery(q, params):
    cur.execute(q, params)
    conn.commit()

def viewAccounts():
    cur.execute("SELECT * FROM Users")
    return cur.fetchall()

def getNewId(table):
    cur.execute("SELECT * FROM " + table)
    all_entries = cur.fetchall()
    ids = [entry[0] for entry in all_entries]
    if len(ids) > 0:
        return max(ids) + 1
    else:
        return 0

def checkToken(tok):
    cur.execute("SELECT Username, Token FROM Users")
    result = cur.fetchall()
    alltok = {entry[1] : entry[0] for entry in result}
    if tok in alltok:
        return alltok[tok]
    return False
    
def nameAvailable(uname):
    cur.execute("SELECT * FROM Users WHERE Username = ?", (uname,))
    result = cur.fetchone()
    return result is None


def getPWHash(uname):
    cur.execute("SELECT Passhash FROM Users WHERE Username = ?", (uname,))
    result = cur.fetchone()
    if result is not None:
        return result[0]
    else:
        return result

def getGroupsForOwner(uname):
    cur.execute("SELECT GroupName, GroupID FROM InfoGroup WHERE Owner = ?", (uname,))
    result = cur.fetchall()
    d = {n[0] : n[1] for n in result}
    return d

def getGroupName(gid):
    cur.execute("SELECT GroupName FROM InfoGroup WHERE GroupID = ?", (gid,))
    result = cur.fetchone()
    return result[0]

def createGroup(gname, gid, gowner):
    cur.execute("INSERT INTO InfoGroup VALUES (?, ?, ?, '')", (gid, gname, gowner))
    return conn.commit()
