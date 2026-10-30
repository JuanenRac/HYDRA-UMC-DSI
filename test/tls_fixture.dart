// =============================================================================
// HYDRA-UMC-DSI - test/tls_fixture.dart
// Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
// GPL-3.0-or-later - see LICENSE
//
// A self-signed certificate for localhost and its key, made only for the tests
// of network/tls_settings.dart. It protects nothing: the key is public.
// =============================================================================

const String kTestCertPem = """-----BEGIN CERTIFICATE-----
MIIC9TCCAd2gAwIBAgIUadlUTff3suJOhQ9scb6MfJAzhPMwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MCAXDTI2MTAzMDA3NTgwMFoYDzIxMjYx
MDA2MDc1ODAwWjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDLWzBKGQj6sGf1kWvyZerutXHYmkZeoD55Nu+4GyVg
RZiwHmr4uNDRfgqlyV3yioFjZhuDyMhvh96tXSuHAC96kMFIaVVimluxXzHX1PVt
gy3lRlips3rKxi5Z8YfCR3uNY+jD6wtyykxUKVBh+cWSwmXq7efF7GeF2WhJFuk2
LKSrLJi9enKnMfxNG84o9Ny3gMVUuqgSSYKC3SSco8uP18kHv0+KvTdJu+UVT5uo
3+qJg3yMLT2KKzfC3su9f1VXcbcNhPRzKJXHT6jGXpvkjvPSb2nrtJfkcSVBAgUH
ouUvtOidTW3nLH50X9ebevBOTCQM6Vpzv/9IMed3B3F/AgMBAAGjPTA7MBoGA1Ud
EQQTMBGCCWxvY2FsaG9zdIcEfwAAATAdBgNVHQ4EFgQUepR4BBegTi6k55wQAiuH
+ABwA1owDQYJKoZIhvcNAQELBQADggEBAIzKa2uLQIom7A2+4pSKdD6J2IhrJUYM
ng0/v8lMTIOjrIlNYPtUS1p48cgDZX4HSIwFXlAWAK2zDm92bbGw7hsvPrA1ASt2
2qh9VsJCcl75MI+I/o7Xu1HGeLPDb5mnK3NtKgJSLvr+aOigirB31//PXmO4qDOB
8KgrEd/X3L4TZDTiNBQTCVVQRM5pd18huLMJOnc4v+3Uxim70TiFBKTirDEmqymg
Wm1fj2DSxIkWe7HU+xA+Q1L8lOd2pvfsaxN5mTc7jA0RpWR/Ey7cKdCyLlOtnclM
Hf/VI5XzMiHdi34AIvL3nBqoJGVv8KramFI9/Rge/RFQZmaP/qtkmlg=
-----END CERTIFICATE-----
""";

/// The private key, put together here so that no file of the repository holds a
/// complete PEM block of a key.
final String kTestKeyPem = '-----BEGIN ' 'PRIVATE KEY-----\n'
    'MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDLWzBKGQj6sGf1\nkWvyZerutXHYmkZeoD55Nu+4GyVgRZiwHmr4uNDRfgqlyV3yioFjZhuDyMhvh96t\nXSuHAC96kMFIaVVimluxXzHX1PVtgy3lRlips3rKxi5Z8YfCR3uNY+jD6wtyykxU\nKVBh+cWSwmXq7efF7GeF2WhJFuk2LKSrLJi9enKnMfxNG84o9Ny3gMVUuqgSSYKC\n3SSco8uP18kHv0+KvTdJu+UVT5uo3+qJg3yMLT2KKzfC3su9f1VXcbcNhPRzKJXH\nT6jGXpvkjvPSb2nrtJfkcSVBAgUHouUvtOidTW3nLH50X9ebevBOTCQM6Vpzv/9I\nMed3B3F/AgMBAAECggEAMX3Z/M6m/swcIQnpaa8gRERolrzFT5ZUXg/eu8HvkMSf\nao2cnzfrqnCwirS9ZqAK6XQaUjJ1hZ9dtHeudka3R28fe04Xd831bu+qI8syiBqa\n+ufqADMsOVmOQlmkHsZi7YBZUAVOXfuaJAmCBLZTPWqOf2SzOdpVP6Av30nyLDq2\nL9me5lkk7GhURlRIKCWV7S/6Jme3ZGD7U26Z3vhASjrv+Pc+QBWTurd2FUuSOh5E\nocRGX/oDiTbvHC0XjfG9Jz5BJgkdpPzjEstyhpUzDlMDJuyrzUku5+wv1uX8hplK\ns9gj2bdGhhfy6edPpefpwM6PkrDLFfFJoGmnCQaqAQKBgQDml0jhmWUMaEZytUEE\nJhTirsqJTfuGx6Wgu7ygQtoCilB40vN5TuujhzccKiHNmtKEtl65OGe6Fak2K2O2\n5Dj3HmsJRVKEsdkwzZ1QMedzU92poZj6MsVmS1mx69QvAhQH+V5aYEkx6BVRSfGy\n2kuKyPi/bVBd+3ivDcidqc4f/wKBgQDhw6ROJC3fHFPy51uyN8/9U/TfcWLQE4SW\nwLVH8eCnDT67MrjpBezNHk51UTs7AiKaoRWsb4g1sD0tjSQoejy4aKwmUGT3ssKZ\n+mT+w0WqYvLQoL3/FUVpf7816EwuGHfTyePFEWf/j8qJbKZLUdYRHhYLE1hvokq5\nEpYb85augQKBgQCWlm+7HMD35FU1bhdCjVgQXZPZLTs43sLUgCYEBwR2qjs5XJIy\nQ47xYUllNEKVEimvD6Y2kZZz2NeDj7xz4QEuqQe/qyzjiX3MOEsm5yA+maNltym/\nI070qfqujdMoy9OnDXxHyx+h3u2lA4Q7iAHTZcHEya+1YJeEwpykEhORowKBgQCc\n1waZRqcbfZmQgUwBpqZ2zlGqvSGxfi25cU0/Gvk/9IKlGBq/v97/rNNCy1kDqHsT\nw17EOYN+EN6fe5MoD6uJTSZzQ5yxO93XjM2G82+9bBpV96WmxUdAgH/82lG6IEN2\nvaXfrTT7pRBGolVws/ysTaNwtFLW0v9oTVI9Pt9qgQKBgD489IkoqhEIPNo5XE+f\nh8LxVrFr8yS7ADWW78EGLfu7OwrMmIV+9ATD++8vZnBOVO4rUvmv9YDG+eeOlMQf\nI1/k6S/re/v4JzqT/LIe2Y4HYlGqHDqOqU2GOpwY0fSxdgDg6BOIvyYtbGRanqA+\nJzd3LCuRQIEkUSqJ/Y9vfmsF\n'
    '-----END ' 'PRIVATE KEY-----\n';

/// SHA-256 of the DER of [kTestCertPem], as 64 lowercase hex digits.
const String kTestCertFingerprint = '829d7af7e3d850e48426d228592679d023111cc931e092a8fc9949707e106a9c';
