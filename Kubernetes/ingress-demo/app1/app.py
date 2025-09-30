from flask import Flask, render_template_string

app = Flask(__name__)

HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Ingress Demo</title>
</head>
<body>
    <h1>Ingress Demo</h1>
    <img src="/static/ingress.jpg" alt="Ingress Logo" width="300">
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
