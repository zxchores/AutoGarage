# Схема Firestore

```
users/{uid}
  name: string
  city: string
  xp: number
  garageValue: number
  totalHp: number
  bodykits: number
  rarest: string
  createdAt: timestamp

users/{uid}/garage_cars/{carId}
  photoPath: string
  spottedAt: timestamp
  city: string
  lat: number
  lng: number
  make, model, generation, color, bodyType
  yearFrom, yearTo
  rarity, priceRub, horsepower, zeroToHundred, drivetrain
  condition, photoQuality, confidence
  tuning: map
  xpEarned: number

users/{uid}/achievements/{id}
  unlockedAt: timestamp

city_leaderboards/{cityId}
  updatedAt: timestamp
  topXp: array
  topValue: array

duels/{duelId}
  challengerId, opponentId
  userPoints, rivalPoints
  breakdown: map
  createdAt: timestamp
```

Писать лидерборд должен только backend (Cloud Functions), клиенту — чтение.
