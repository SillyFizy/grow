🪴 Grow | تطبيق نمو

A comprehensive plant classification and tracking system with location-based monitoring features.

📋 Project Overview

Grow is a dual-language (Arabic/English) plant classification and tracking application designed to help users identify, learn about, and track plant species. The system combines an authoritative botanical database with crowd-sourced location tracking, creating a valuable resource for researchers, educators, students, and plant enthusiasts.

✨ Key Features

Comprehensive Plant Database: Detailed botanical information including scientific names, common names in both Arabic and English, and botanical characteristics

Multilingual Support: Full Arabic and English interface and content

Location Tracking: Map-based plant sightings with GPS integration

User Contributions: Submit new plant locations and suggest plant additions

Advanced Search: Find plants by name, classification, or characteristics

Offline Capability: Basic functionality when offline with synchronization

Admin Dashboard: Review and moderate user submissions

🛠️ Technologies

Backend

Django 5.0.2

Django REST Framework 3.14.0

PostgreSQL

JWT Authentication

Python 3.8+

Frontend

Flutter

Dart

Google Maps integration

Local storage with Shared Preferences

📥 Installation

Prerequisites

Python 3.8+

PostgreSQL 12.0+

Flutter SDK

Android Studio or Xcode for mobile deployment

Backend Setup

Clone the repository:

git clone https://github.com/yourusername/grow.git
cd grow/backend


Create and activate a virtual environment:

python -m venv venv

# On Windows
venv\Scripts\activate

# On macOS/Linux
source venv/bin/activate


Install dependencies:

pip install -r requirements.txt


Create a .env file in the backend directory with the following variables:

DJANGO_SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://10.0.2.2:3000

# Database settings
DB_NAME=grow_db
DB_USER=postgres
DB_PASSWORD=yourpassword
DB_HOST=localhost
DB_PORT=5432


Create the PostgreSQL database:

createdb grow_db


Run migrations:

python manage.py migrate


Create a superuser:

python manage.py createsuperuser


Start the development server:

python manage.py runserver


Frontend Setup

Navigate to the frontend directory:

cd ../frontend


Get Flutter dependencies:

flutter pub get


Update the API base URL in lib/config/app_config.dart if needed

Run the app in development mode:

# For Android
flutter run

# For iOS (requires macOS)
flutter run -d ios


📱 Usage Examples

User Authentication

Open the app and navigate to the login screen

Create a new account or login with existing credentials

Access features requiring authentication such as submitting plant locations

Browsing Plants

Navigate to the Categories screen

Select a plant classification (e.g., "Wild Plants")

Browse through the available plants

Tap on a plant to view detailed information

Adding Plant Locations

Navigate to the Map screen

Tap on a location or use your current position

Select a plant from the database

Specify quantity and optional notes

Submit the location

🌐 API Endpoints

Authentication

Register a new user:

POST /api/auth/register/
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "securepassword",
  "password2": "securepassword"
}


Login:

POST /api/auth/login/
{
  "login": "username_or_email",
  "password": "yourpassword"
}


Plants

Get all plants:

GET /api/plants/


Get plants by classification:

GET /api/plants/?classification=طبي


Search plants:

GET /api/plants/search/?q=search_term


Get plant details:

GET /api/plants/5/


Plant Locations

Submit a new plant location:

POST /api/plant-locations/
{
  "plant": 5,
  "latitude": 33.315254,
  "longitude": 44.366127,
  "quantity": 3,
  "notes": "Healthy plants found near the river"
}


Get plant locations for a specific plant:

GET /api/plants/5/locations/


Get user's plant location statistics:

GET /api/users/me/location-stats/


📌 Example Response

Plant details endpoint (GET /api/plants/5/):

{
  "id": 5,
  "name_arabic": "القطن",
  "name_english": "Cotton",
  "name_scientific": "Gossypium hirsutum",
  "family": {
    "id": 2,
    "name_arabic": "الخبازية",
    "name_english": "Malvaceae",
    "name_scientific": "Malvaceae",
    "description_arabic": "تضم نباتات عشبية وخشبية...",
    "description_english": "Family of flowering plants..."
  },
  "classification": "اقتصادي",
  "description": "نبات القطن من أهم المحاصيل الاقتصادية في العالم...",
  "seed_shape_arabic": "بيضاوي",
  "seed_shape_english": "Oval",
  "cotyledon_type": "DI",
  "flower_type": "HERMAPHRODITE",
  "hermaphrodite_flower": {
    "sepal_arrangement": "RANGE",
    "sepal_range_min": 5,
    "sepal_range_max": 5,
    "sepals_fused": true,
    "petal_arrangement": "RANGE",
    "petal_range_min": 5,
    "petal_range_max": 5,
    "petals_fused": false,
    "stamens": "Multiple stamens fused into a column",
    "carpels": "3-5 fused carpels"
  },
  "image_url": "http://localhost:8000/media/plants/cotton.jpg"
}


🧪 Running Tests

Backend Tests

cd backend
python manage.py test


Frontend Tests

cd frontend
flutter test


📊 Admin Dashboard

The admin dashboard provides tools for managing the plant database and moderating user submissions:

Access at http://localhost:8000/admin/ after starting the backend server

Login with the superuser credentials created during setup

Navigate to the Plants section to manage plant records

Review and approve Plant Submissions from users

🙏 Acknowledgments

Flutter and Django communities for their excellent documentation

Contributors to the open-source packages used in this project

Special thanks to botanical experts who provided plant classification guidance

📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

📬 Contact

For questions or suggestions, please open an issue on GitHub or contact the project maintainers.