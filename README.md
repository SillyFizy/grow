# 🪴 Grow | تطبيق نمو

A comprehensive plant classification and tracking system with location-based monitoring features.


## 📋 Project Overview

Grow is a dual-language (Arabic/English) plant classification and tracking application designed to help users identify, learn about, and track plant species. The system combines an authoritative botanical database with crowd-sourced location tracking, creating a valuable resource for researchers, educators, students, and plant enthusiasts.

## ✨ Key Features

- **Comprehensive Plant Database**: Detailed botanical information including scientific names, common names in both Arabic and English, and botanical characteristics
- **Multilingual Support**: Full Arabic and English interface and content
- **Location Tracking**: Map-based plant sightings with GPS integration
- **User Contributions**: Submit new plant locations and suggest plant additions
- **Advanced Search**: Find plants by name, classification, or characteristics
- **Offline Capability**: Basic functionality when offline with synchronization
- **Admin Dashboard**: Review and moderate user submissions

## 🛠️ Technologies

### Backend
- Django 5.0.2
- Django REST Framework 3.14.0
- PostgreSQL
- JWT Authentication
- Python 3.8+

### Frontend
- Flutter
- Dart
- Google Maps integration
- Local storage with Shared Preferences

## 📥 Installation

### Prerequisites
- Python 3.8+
- PostgreSQL 12.0+
- Flutter SDK
- Android Studio or Xcode for mobile deployment

### Backend Setup

1. Clone the repository:
```bash
git clone https://github.com/SillyFizy/grow.git
cd grow/backend
```

2. Create and activate a virtual environment:
```bash
python -m venv venv

# On Windows
venv\Scripts\activate

# On macOS/Linux
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file in the backend directory with the following variables:
```
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
```

5. Create the PostgreSQL database:
```bash
createdb grow_db
```

6. Run migrations:
```bash
python manage.py migrate
```

7. Create a superuser:
```bash
python manage.py createsuperuser
```

8. Start the development server:
```bash
python manage.py runserver
```

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd ../frontend
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Update the API base URL in `lib/config/app_config.dart` if needed

4. Run the app in development mode:
```bash
# For Android
flutter run

# For iOS (requires macOS)
flutter run -d ios
```

## 📱 Usage Examples

### User Authentication

1. Open the app and navigate to the login screen
2. Create a new account or login with existing credentials
3. Access features requiring authentication such as submitting plant locations

### Browsing Plants

1. Navigate to the Categories screen
2. Select a plant classification (e.g., "Wild Plants")
3. Browse through the available plants
4. Tap on a plant to view detailed information

### Adding Plant Locations

1. Navigate to the Map screen
2. Tap on a location or use your current position
3. Select a plant from the database
4. Specify quantity and optional notes
5. Submit the location

## 🌐 API Endpoints

### Authentication

Register a new user:
```bash
POST /api/auth/register/
{
  "username": "newuser",
  "email": "user@example.com",
  "password": "securepassword",
  "password2": "securepassword"
}
```

Login:
```bash
POST /api/auth/login/
{
  "login": "username_or_email",
  "password": "yourpassword"
}
```

### Plants

Get all plants:
```bash
GET /api/plants/
```

Get plants by classification:
```bash
GET /api/plants/?classification=طبي
```

Search plants:
```bash
GET /api/plants/search/?q=search_term
```

Get plant details:
```bash
GET /api/plants/5/
```

### Plant Locations

Submit a new plant location:
```bash
POST /api/plant-locations/
{
  "plant": 5,
  "latitude": 33.315254,
  "longitude": 44.366127,
  "quantity": 3,
  "notes": "Healthy plants found near the river"
}
```

Get plant locations for a specific plant:
```bash
GET /api/plants/5/locations/
```

Get user's plant location statistics:
```bash
GET /api/users/me/location-stats/
```

## 📌 Example Response

Plant details endpoint (`GET /api/plants/5/`):

```json
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
```

## 🧪 Running Tests

### Backend Tests
```bash
cd backend
python manage.py test
```

### Frontend Tests
```bash
cd frontend
flutter test
```

## 📊 Admin Dashboard

The admin dashboard provides tools for managing the plant database and moderating user submissions:

1. Access at `http://localhost:8000/admin/` after starting the backend server
2. Login with the superuser credentials created during setup
3. Navigate to the Plants section to manage plant records
4. Review and approve Plant Submissions from users

## 🙏 Acknowledgments

- Flutter and Django communities for their excellent documentation
- Mayar Yasser for her being an amazing person

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📬 Contact

For questions or suggestions, please open an issue on GitHub or contact the project maintainers.
