/*
 * Copyright 2020, Tekartik UG
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,

 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Basic service worker for sqflite_common_ffi_web

// version 0.1.0
const version = '0.1.0';
const cacheName = 'sqflite_common_ffi_web';
const cacheVersion = 'v1';
const cacheId = `${cacheName}-${cacheVersion}`;
const wasmFilePath = 'sqlite3.wasm';

// On install, cache the wasm file
self.addEventListener('install', (event) => {
    // console.log(`[sw] install version ${version}`);
    event.waitUntil(
        caches.open(cacheId).then((cache) => {
            return cache.add(wasmFilePath).then(() => {
                // console.log(`[sw] wasm file cached ${wasmFilePath}`);
            });
        }),
    );
});

self.addEventListener('activate', (event) => {
    // console.log('[sw] activate');
    event.waitUntil(
        // Clean up old caches
        caches.keys().then((keys) => {
            return Promise.all(
                keys.map((key) => {
                    if (key.startsWith(cacheName) && key !== cacheId) {
                        // console.log(`[sw] deleting old cache ${key}`);
                        return caches.delete(key);
                    }
                }),
            );
        }),
    );
});
// On fetch, try to get the wasm file from cache
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);
    if (url.pathname.endsWith(wasmFilePath)) {
        // console.log(`[sw] fetch ${url.pathname}`);
        event.respondWith(
            caches.open(cacheId).then((cache) => {
                return cache.match(event.request).then((response) => {
                    return (
                        response ||
                        fetch(event.request).then((response) => {
                            cache.put(event.request, response.clone());
                            return response;
                        })
                    );
                });
            }),
        );
    }
});