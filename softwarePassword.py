Python 3.14.2 (tags/v3.14.2:df79316, Dec  5 2025, 17:18:21) [MSC v.1944 64 bit (AMD64)] on win32
Enter "help" below or click "Help" above for more information.
>>> from flask import Flask, request, jsonify
... from flask_bcrypt import Bcrypt
... 
... app = Flask(__name__)
... # Initialize the Bcrypt extension with your app instance
... bcrypt = Bcrypt(app)
... 
... # Mock database dictionary for demonstration
... user_database = {}
... 
... @app.route('/register', methods=['POST'])
... def register():
...     data = request.get_json()
...     username = data.get('username')
...     password = data.get('password')
...     
...     # Generate a secure bcrypt hash (automatically salts the password)
...     hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
...     
...     # Store the string hash in your database
...     user_database[username] = hashed_password
...     return jsonify({"message": "User registered successfully!"}), 201
... 
... @app.route('/login', methods=['POST'])
... def login():
...     data = request.get_json()
...     username = data.get('username')
...     password = data.get('password')
...     
...     stored_hash = user_database.get(username)
...     
...     # Check the plaintext password against the stored secure hash
...     if stored_hash and bcrypt.check_password_hash(stored_hash, password):
...         return jsonify({"message": "Login successful!"}), 200
...     
...     return jsonify({"error": "Invalid username or password"}), 401
... 
if __name__ == '__main__':
