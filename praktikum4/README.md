# Tugas 4 Praktikum Sistem Informasi Geografis: Query Spasial & Relasi Topologi

Repositori ini berisi laporan Tugas Praktikum 4 mata kuliah Sistem Informasi Geografis, berfokus pada analisis data spasial menggunakan skema transportasi di PostgreSQL/PostGIS.

## Identitas Mahasiswa
- **Nama:** Muhammad Bimastiar
- **NIM:** 123140211
- **Kelas:** Sistem Informasi Geografis
- **Dosen Pengampu:** 1. Muhammad Habib Alghifari, S.Kom., M.T.I.  --
  2. Alya Khairunnisa Rizkita, S.Kom., M.Kom.

---

## Deskripsi Tugas
Melakukan analisis spasial menggunakan fungsi pengukuran dan relasi topologi pada data transportasi. Tugas ini mencakup implementasi 8 query berbeda termasuk pencarian jarak (ST_Distance), pengukuran luas/panjang (ST_Area & ST_Length), relasi persinggungan (ST_Intersects & ST_Contains), agregasi data (GROUP BY), hingga algoritma K-NN.

---

## Langkah-langkah dan Analisis Spasial

### 1. Pengecekan Kesiapan *Environment* PostGIS
Sebelum melakukan analisis, dilakukan pengecekan ekstensi PostGIS dan sistem referensi koordinat (SRID) pada tabel spasial.

```sql
SELECT PostGIS_Version();
SELECT f_table_name, f_geometry_column, srid, type FROM geometry_columns;

```

...

**Interpretasi:** Pengecekan ini memastikan bahwa ekstensi spasial aktif dan seluruh tabel pada skema transportasi memiliki format geometri yang valid.

### 2. Fungsi Pengukuran: ST_Distance

Menghitung jarak dari 'Halte Tanjung Karang' ke seluruh fasilitas parkir.

```sql
SELECT 
    a.nama AS nama_halte, 
    b.nama AS lokasi_parkir, 
    ROUND(ST_Distance(a.geom::geography, b.geom::geography)) AS jarak_meter
FROM transportasi.halte a
CROSS JOIN transportasi.parkir b
WHERE a.nama = 'Halte Tanjung Karang'
ORDER BY jarak_meter ASC;

```

...

**Interpretasi:** Tipe geometri di-*cast* ke tipe `geography` untuk menghasilkan perhitungan jarak dalam meter, mempermudah identifikasi lahan parkir terdekat.

### 3. Fungsi Relasi Topologi: ST_Intersects

Mencari rute transportasi yang melintasi wilayah Kecamatan Rajabasa.

```sql
SELECT 
    a.nama_rute, 
    a.jenis AS jenis_angkutan,
    b.nama AS kecamatan
FROM transportasi.rute a
JOIN transportasi.wilayah b ON ST_Intersects(a.geom, b.geom)
WHERE b.nama = 'Rajabasa';

```

...

**Interpretasi:** `ST_Intersects` mengevaluasi persinggungan antara garis (rute) dan poligon (wilayah), menghasilkan daftar trayek angkutan yang melayani kecamatan tersebut.

### 4. Agregasi Spasial: ST_Within & GROUP BY

Menghitung total insiden kecelakaan lalu lintas di setiap kecamatan.

```sql
SELECT 
    a.nama AS kecamatan, 
    COUNT(b.id) AS total_kecelakaan
FROM transportasi.wilayah a
LEFT JOIN transportasi.kecelakaan b ON ST_Within(b.geom, a.geom)
GROUP BY a.nama
ORDER BY total_kecelakaan DESC;

```

...

**Interpretasi:** Menggabungkan evaluasi spasial (`ST_Within`) dengan fungsi agregasi (`COUNT`) untuk merangkum tingkat kerawanan wilayah secara efisien.

### 5. Algoritma K-NN: Pencarian Fasilitas Terdekat

Mencari 3 fasilitas parkir terdekat dari lokasi kecelakaan tertentu menggunakan indeks spasial.

```sql
SELECT 
    b.nama AS lokasi_parkir,
    a.jenis_kecelakaan,
    ROUND(ST_Distance(a.geom::geography, b.geom::geography)) AS jarak_meter
FROM transportasi.kecelakaan a
CROSS JOIN transportasi.parkir b
WHERE a.id = 1
ORDER BY a.geom <-> b.geom
LIMIT 3;

```

...

**Interpretasi:** Penggunaan operator `<->` memanfaatkan *spatial index* untuk proses komputasi pencarian lokasi terdekat yang jauh lebih ringan dan cepat.

### 6. Analisis Radius: ST_DWithin

Mencari halte yang berada dalam radius pejalan kaki (500 meter) dari Stasiun Tanjung Karang.

```sql
SELECT 
    a.nama AS halte_terdekat, 
    a.jenis,
    b.nama AS titik_pusat
FROM transportasi.halte a
JOIN transportasi.parkir b ON ST_DWithin(a.geom::geography, b.geom::geography, 500)
WHERE b.nama = 'Parkir Stasiun Tanjung Karang';

```

...

**Interpretasi:** `ST_DWithin` menyeleksi geometri yang berada dalam area *buffer* imajiner sebesar 500 meter, sangat cocok untuk memetakan *catchment area* (area jangkauan) fasilitas.

### 7. Fungsi Pengukuran Area: ST_Area (Query Tambahan 1)

Menghitung luas wilayah setiap kecamatan dalam satuan Kilometer Persegi (km²).

```sql
SELECT 
    a.nama AS kecamatan, 
    ROUND((ST_Area(a.geom::geography) / 1000000)::numeric, 2) AS luas_km2
FROM transportasi.wilayah a
ORDER BY luas_km2 DESC;

```

...

**Interpretasi:** Fungsi `ST_Area` dengan *casting geography* menghasilkan luas dalam meter persegi. Kemudian dibagi 1.000.000 untuk mengonversinya menjadi kilometer persegi agar lebih mudah dianalisis skala perkotaannya.

### 8. Fungsi Pengukuran Panjang: ST_Length (Query Tambahan 2)

Menghitung total panjang lintasan untuk masing-masing rute transportasi.

```sql
SELECT 
    a.nama_rute, 
    a.jenis, 
    ROUND(ST_Length(a.geom::geography)::numeric, 2) AS panjang_meter
FROM transportasi.rute a
ORDER BY panjang_meter DESC;

```

...

**Interpretasi:** Fungsi `ST_Length` digunakan pada data geometri bertipe garis (LineString) untuk mengetahui jarak tempuh operasional dari masing-masing rute angkutan.

### 9. Fungsi Relasi Topologi: ST_Contains (Query Tambahan 3)

Memeriksa fasilitas halte apa saja yang berada tepat di dalam wilayah Kecamatan Sukarame.

```sql
SELECT 
    a.nama AS nama_wilayah, 
    b.nama AS nama_halte
FROM transportasi.wilayah a
JOIN transportasi.halte b ON ST_Contains(a.geom, b.geom)
WHERE a.nama = 'Sukarame';

```

...

**Interpretasi:** Berbeda dengan `ST_Intersects`, fungsi `ST_Contains` lebih ketat karena memastikan geometri titik halte (Point) sepenuhnya terkandung di dalam batas poligon kecamatan tersebut.

---

## Kesimpulan

Penggabungan fungsi pengukuran (ST_Distance, ST_Area, ST_Length), fungsi relasi (ST_Intersects, ST_Within, ST_Contains), dan pemanfaatan indeks spasial (K-NN dan ST_DWithin) di PostGIS memungkinkan analisis data geografis secara cepat dan mendalam. Operasi ini sangat krusial dalam perencanaan transportasi perkotaan, seperti untuk pencarian lokasi evakuasi, evaluasi cakupan layanan, maupun pemetaan kepadatan insiden lalu lintas.
