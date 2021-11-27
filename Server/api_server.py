from datetime import datetime
from flask import Flask
from flask import make_response
from flask import jsonify
from flask import request
from functions import get_signals


app = Flask(__name__)


@app.route('/goml/v1.0/signals', methods=['GET'])
def signals():
    auth_code = request.cookies.get('auth')
    if auth_code == 'XXXXX':
        return jsonify({'signals': get_signals()})
    else:
        return jsonify({'error': 'No license found'})


@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found'}), 404)


@app.errorhandler(403)
def forbidden(error):
    return make_response(jsonify({'error': 'Forbidden'}), 403)


@app.route('/', methods=['GET'])
def index():
    return jsonify({'Hello': 'Working'})
