from flask import Flask, render_template, redirect, url_for, session, request
import subprocess
import hashlib
import sqlite3

app = Flask(__name__)

app.secret_key = '*********************************8'

def get_db_connection ():
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

# Главная страница
@app.route('/', methods=['GET', 'POST'])
def admin_login():
    error = None
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        hashed_password = hashlib.sha256(password.encode('utf-8')).hexdigest()
        #Подключение к БД
        conn = get_db_connection()
        #создаем запрос по поиску пользователя по username, если ок плучаем ид и пароль
        user = conn.execute('SELECT * FROM users WHERE username = ?',(username,)).fetchone()
        #закрываем подключение к бд
        conn.close()

        if user and user['password'] == hashed_password:
            session['user_id'] = user['id']
            return redirect(url_for('index'))
        
        else:
            error = 'Неправильное имя пользователя или пароль'

    # Если GET запрос, показываем форму входа
    return render_template('login.html', error=error)

@app.route('/logout')
def logaut():
    session.clear()
    return redirect(url_for('login_adm'))

@app.route('/home')
def index():
    if 'user_id' not in session:
        return redirect(url_for('/'))
    return render_template('index.html')

@app.route('/about')
def about():
  return render_template('about.html')

# Обработка отправки формы
@app.route('/run', methods=['POST'])
def run_powershell():
    input_string = request.form['input_string']

    # Команда для вызова PowerShell-скрипта
    powershell_command = ["powershell", "-ExecutionPolicy Bypass -Noninteractive -File", "C:\\TEST\\scriptsMY\\my\\py\\Web\\first\\static\\test.ps1", "-CompName", input_string]

    try:
        # Запуск PowerShell-скрипта
        result = subprocess.run(
            powershell_command,
            capture_output=True,
            text=True
        )
        output = result.stdout
        error = result.stderr

        if error:
            return render_template('result.html', result_type = 'Ошибка', message = error)
        return render_template('result.html', result_type = 'Результат', message = output)
    except Exception as e:
        return render_template('result.html', result_type = 'Ошибка выполнения', message = str(e))
    
@app.route('/run1', methods=['POST'])
def run_powershell1():
    input_string = request.form['input_string']

    # Команда для вызова PowerShell-скрипта
    powershell_command = ["powershell", "-ExecutionPolicy Bypass -Noninteractive -File", "C:\\TEST\\scriptsMY\\my\\py\\Web\\first\\static\\watchDLP.ps1", "-CompName", input_string]

    try:
        # Запуск PowerShell-скрипта
        result = subprocess.run(
            powershell_command,
            capture_output=True,
            text=True
        )
        output = result.stdout
        error = result.stderr

        if error:
            return render_template('result.html', result_type = 'Ошибка', message = error)
        return render_template('result.html', result_type = 'Результат', message = output)
    except Exception as e:
        return render_template('result.html', result_type = 'Ошибка выполнения', message = str(e))

@app.route('/upn', methods=['POST'])
def run_powershellupn():
    input_string = request.form['input_string']

    # Команда для вызова PowerShell-скрипта
    powershell_command = ["powershell", "-ExecutionPolicy Bypass -Noninteractive -File", "C:\\TEST\\scriptsMY\\my\\py\\Web\\first\\static\\UPN.ps1", "-folder", input_string]

    try:
        # Запуск PowerShell-скрипта
        result = subprocess.run(
            powershell_command,
            capture_output=True,
            text=True
        )
        output = result.stdout
        error = result.stderr

        if error:
            return render_template('result.html', result_type = 'Ошибка', message = error)
        return render_template('result.html', result_type = 'Результат', message = output)
    except Exception as e:
        return render_template('result.html', result_type = 'Ошибка выполнения', message = str(e))
    

if __name__ == '__main__':
    app.run(debug=True)