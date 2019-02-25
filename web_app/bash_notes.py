from flask import Flask, render_template, request, session, redirect, url_for, send_from_directory
import bcrypt, json, secrets
import random, os
from utils import dbutils as db
from werkzeug.utils import secure_filename

app = Flask(__name__)
#app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
db.getCursorFromFile('data/data.db')

def check_logged_in():
    print(str(session.keys()))
    if 'username' not in session.keys():
        return redirect(url_for("login"))

def get_group_path(group_id ):
    base_path = os.path.join("groups", str(group_id))
    return base_path
    # return os.path.join("groups", str(group_id))

# Serve up the zesty homepage
@app.route("/")
def home():
    return redirect(url_for("login"))

# Routes related to managing the server
@app.route("/manage")
def manage():
    check_logged_in()
    return render_template("dashboard.html", user=session["username"],
                               notelinks={"a": "b"})
# Check tokens
@app.route("/tokencheck", methods=['POST'])
def tokcheck():
    if db.checkToken(request.get_data()):
        akeys=open("~/.ssh/authorized-keys", 'a')
        akeys.write(request.form["ssh-key"])
        akeys.close()
        os.system("git init --bare %s" % (username.replace('/', '')))
        return "ssh://bashnotes.com:~/bashnotes"
        return "GOOD TOKEN"
    return "BAD TOKEN"


@app.route("/manage/creategroup", methods=['GET', 'POST'])
def creategroup():
    check_logged_in()
    if request.method == 'GET':
        return render_template('create_group.html')
    elif request.method == 'POST':
        gname = request.form["group-name"]
        gid = db.getNewId("InfoGroup")
        gowner = session['username']
        db.createGroup(gname, gid, gowner)
        new_group = os.path.join('groups', str(gid))
        os.mkdir(new_group)
        return redirect(url_for("manage"))

@app.route('/preview/group/<int:gid>')
def preview_group(gid):
    check_logged_in()
    return render_template("groups/" + str(gid) + ".html", group_id = gid, media = os.listdir(get_group_path(gid)))

@app.route("/login", methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return(render_template('login.html'))
    if request.method == 'POST':
        if not "username" in session.keys():
            uname = "".join(request.form["username"].split())
            pw = request.form["pass"]
            conf = request.form["conf"]
            if conf == pw and db.nameAvailable(uname):
                hashpw = bcrypt.hashpw(pw.encode("UTF-8"), bcrypt.gensalt())
                db.execQuery("INSERT INTO Users VALUES (?, ?, ?)", (uname, hashpw, secrets.token_hex()))
                return redirect(url_for("manage"))
            pwhash = db.getPWHash(uname)
            success = pwhash is not None and bcrypt.hashpw(pw.encode("UTF-8"), pwhash) == pwhash
            if success:
                session["username"] = uname
        return redirect(url_for("manage"))


# The route for connecting to the server
@app.route("/connect")
def connect():
    return "You are now KONNECTED"


@app.route('/protected/<int:gid>/<filename>')
def protected(gid, filename):
    check_logged_in()
    print(session.keys())
    print(session.get("username"))
    print(db.getGroupsForOwner(session.get("username")))
    if gid in db.getGroupsForOwner(session["username"]).values():
        return send_from_directory(
            "groups/" + str(gid),
            filename
        )
    else:
        return str(db.getGroupsForOwner(session["username"]).values())


if __name__ == "__main__":
    app.debug = True
    rkey = str(random.getrandbits(50))
    app.secret_key = rkey
    app.run()
