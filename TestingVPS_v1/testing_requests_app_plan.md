# Testing Requests — План приложения

> Простое приложение для тестирования HTTP-запросов к серверу `behav10urvps.top`.
> Один экран, три файла, MVVM архитектура.

---

## Структура проекта

```
TestingRequests/
├── Models/
│   └── RequestType.swift        ← enum с типами запросов
├── ViewModels/
│   └── RequestViewModel.swift   ← логика запросов к серверу
└── Views/
    └── ContentView.swift        ← единственный экран
```

---

## Файл 1: `RequestType.swift` (Модель)

### Что это

`enum` (перечисление) — тип с фиксированным набором вариантов. Здесь это список запросов, которые можно отправить серверу.

### Объявление

```
enum RequestType: String, CaseIterable, Identifiable
```

- `String` — raw value, каждый кейс имеет строковое значение
- `CaseIterable` — даёт `RequestType.allCases` (массив всех кейсов), нужно для ForEach в Picker
- `Identifiable` — нужно чтобы SwiftUI различал элементы в списке

### Кейсы

| Кейс | Что делает |
|------|-----------|
| `health` | Проверка что сервер жив |
| `echo` | Отправляет JSON, получает его обратно |
| `testError` | Получает ошибку 500 от сервера |
| `testDelay` | Получает ответ с задержкой 3 секунды |

### Computed Properties (3 штуки)

**1. `id: String`**
- Возвращает `rawValue`
- Нужно для протокола `Identifiable`

**2. `displayName: String`**
- Человекочитаемое название для отображения в Picker
- Используй `switch self` и верни строку для каждого кейса:
  - `.health` → `"Health Check"`
  - `.echo` → `"Echo POST"`
  - `.testError` → `"Error 500"`
  - `.testDelay` → `"Delay 3s"`

**3. `url: String`**
- Полный URL для запроса
- Тоже через `switch self`:
  - `.health` → `"https://behav10urvps.top/health"`
  - `.echo` → `"https://behav10urvps.top/api/v1/echo"`
  - `.testError` → `"https://behav10urvps.top/api/v1/test-error/500"`
  - `.testDelay` → `"https://behav10urvps.top/api/v1/test-delay/3"`

**4. `httpMethod: String`**
- HTTP метод запроса
  - `.echo` → `"POST"` (отправляем данные)
  - Все остальные → `"GET"` (просто запрашиваем)

---

## Файл 2: `RequestViewModel.swift` (Вью-модель)

### Объявление

```
@MainActor @Observable class RequestViewModel
```

- `@Observable` — макрос, чтобы SwiftUI автоматически обновлял UI при изменении свойств (как в приложении заметок)
- `@MainActor` — гарантирует что изменение свойств происходит в главном потоке (обязательно, потому что свойства привязаны к UI)

### Свойства (3 штуки)

| Свойство | Тип | Начальное значение | Зачем |
|----------|-----|-------------------|-------|
| `selectedType` | `RequestType` | `.health` | Какой запрос выбран в Picker |
| `responseText` | `String` | `""` | Текст ответа сервера для отображения |
| `isLoading` | `Bool` | `false` | Флаг загрузки (крутилка / блокировка кнопки) |

### API ключ

Объяви приватную константу прямо в классе:

```
private let apiKey = "ТВОЙ_КЛЮЧ_ИЗ_.ENV"
```

Это учебный проект — хардкод ок. Только не пушь на GitHub. Позже вынесешь в `.xcconfig`.

### Метод `sendRequest()` — пошагово

Сигнатура: `func sendRequest() async`

Внутри — 7 шагов:

**Шаг 1: Подготовка**
- Установи `isLoading = true`
- Очисти `responseText = ""`

**Шаг 2: Создание URL**
- Из `selectedType.url` создай `URL` через `URL(string:)`
- Это возвращает Optional → используй `guard let url = URL(string: ...) else { ... }`
- Если `nil` — запиши в `responseText` текст ошибки ("Неверный URL"), установи `isLoading = false`, сделай `return`

**Шаг 3: Создание URLRequest**
- `var request = URLRequest(url: url)`
- Установи HTTP метод: `request.httpMethod = selectedType.httpMethod`

**Шаг 4: Заголовки (если нужны)**
- Если `selectedType != .health` — добавь заголовок авторизации:
  - `request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")`
- Если `selectedType == .echo` — добавь ещё:
  - `request.setValue("application/json", forHTTPHeaderField: "Content-Type")`

**Шаг 5: Тело запроса (только для echo)**
- Если `selectedType == .echo`:
  - Создай словарь: `let body: [String: String] = ["hello": "world"]`
  - Преврати в Data: `request.httpBody = try JSONSerialization.data(withJSONObject: body)`
  - (Это может бросить ошибку — оно внутри do/catch, так что ok)

**Шаг 6: Отправка запроса (do / catch)**

Внутри `do`:
1. `let (data, response) = try await URLSession.shared.data(for: request)`
2. Достань статус код: `let httpResponse = response as? HTTPURLResponse`
3. Из `httpResponse` возьми `.statusCode` (например, 200, 500 и т.д.)
4. Преврати `data` в строку: `let body = String(data: data, encoding: .utf8) ?? "Нет данных"`
5. Собери `responseText`: статус код + перенос строки + тело ответа
   - Например: `"Статус: 200\n\nОтвет:\n{\"status\":\"ok\",...}"`

Внутри `catch`:
- Запиши ошибку: `responseText = "Ошибка: \(error.localizedDescription)"`

**Шаг 7: Завершение**
- После do/catch (не внутри!) установи `isLoading = false`
- Это гарантирует что крутилка остановится в любом случае — и при успехе, и при ошибке

---

## Файл 3: `ContentView.swift` (Вью)

### Подключение вью-модели

```
@State private var viewModel = RequestViewModel()
```

### Структура экрана (VStack, сверху вниз)

Корневой контейнер: `VStack` с `.padding()`

```
VStack (с padding)
│
├── 1. Text("Testing requests")
│       .font(.largeTitle)
│       .bold()
│
├── 2. Spacer()                         ← отталкивает контент вниз
│
├── 3. Picker (выбор типа запроса)
│       selection: $viewModel.selectedType
│       Внутри: ForEach(RequestType.allCases) { type in
│           Text(type.displayName).tag(type)
│       }
│       Стиль: .pickerStyle(.menu)
│
├── 4. Button("Request server!")
│       Действие: Task { await viewModel.sendRequest() }
│       Стиль: .buttonStyle(.borderedProminent)
│       Модификатор: .disabled(viewModel.isLoading)   ← нельзя нажать пока грузится
│
├── 5. Блок ответа сервера
│       ScrollView {
│           if viewModel.isLoading {
│               ProgressView()           ← крутилка пока грузится
│           } else if viewModel.responseText.isEmpty {
│               Text("Здесь будет ответ сервера")
│                   .foregroundStyle(.secondary)
│           } else {
│               Text(viewModel.responseText)
│                   .font(.system(.body, design: .monospaced))
│           }
│       }
│       .frame(maxWidth: .infinity, minHeight: 200)
│       .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
│
└── 6. Spacer()                         ← для баланса
```

### Заметки по UI

- `.font(.system(.body, design: .monospaced))` — моноширинный шрифт для JSON, чтобы было читаемо
- `ScrollView` нужен потому что JSON-ответ может быть длинным (особенно echo)
- Между Picker и Button, Button и блоком ответа можешь добавить `.padding(.vertical)` для пространства между элементами
- `RoundedRectangle` с `.stroke` даст рамку как на твоём макете

---

## Порядок сборки

### Этап 1: Enum
- Создай `RequestType.swift`
- Объяви enum со всеми кейсами и computed properties
- Можешь проверить в `ContentView` что `RequestType.allCases` работает (просто выведи `ForEach`)

### Этап 2: Вью-модель (заглушка)
- Создай `RequestViewModel.swift`
- Объяви класс со свойствами
- В `sendRequest()` пока **без** реального запроса — просто запиши тестовый текст:
  - `responseText = "Тестовый ответ для \(selectedType.displayName)"`
  - Добавь `try await Task.sleep(for: .seconds(1))` чтобы проверить что крутилка работает

### Этап 3: UI
- Собери `ContentView.swift` по схеме выше
- Проверь что:
  - Picker переключается между типами
  - Кнопка запускает "загрузку"
  - Появляется крутилка, потом тестовый текст
  - Кнопка заблокирована пока "грузится"

### Этап 4: Реальный запрос
- Замени заглушку в `sendRequest()` на реальный код с `URLSession` (шаги 2-7)
- Тестируй каждый тип запроса по очереди:
  - `health` — должен вернуть `{"status": "ok", ...}`
  - `echo` — должен вернуть то что отправил + заголовки
  - `testError` — должен вернуть статус 500
  - `testDelay` — должен ответить через 3 секунды (крутилка покрутится)

---

## Что здесь новое (чего ты ещё не делал)

| Концепция | Где используется | Сложность |
|-----------|-----------------|-----------|
| `enum` с computed properties | `RequestType` | Простая — это как struct, но с фиксированными вариантами |
| `CaseIterable` | Picker + ForEach | Одна строка — даёт `.allCases` |
| `URLRequest` | `sendRequest()` | Новое, но линейное — создал, настроил, отправил |
| `URLSession.shared.data(for:)` | `sendRequest()` | Одна строка с `try await` |
| `@MainActor` | Вью-модель | Одно слово — просто добавь перед классом |
| `JSONSerialization` | Тело для echo | Одна строка — превращает словарь в Data |

Всё остальное — SwiftUI, MVVM, @Observable, @State, Picker, Button, VStack — ты уже знаешь и использовал.
