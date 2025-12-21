# ReactNodeTesting

- to make pr

A sample React and Node/Express shopping cart application demonstrating comprehensive testing techniques using **React Testing Library** and **Jest**.

📄 [Companion Article on Medium](https://medium.com/@eljamaki01/testing-a-react-node-express-app-with-react-test-library-and-jest-2ac910812c41)

---

## Overview

This project showcases a simulated e-commerce shopping cart with:

- **Frontend**: React 17 with Material-UI components
- **Backend**: Node.js/Express REST API
- **Testing**: Jest + React Testing Library with various testing patterns

## Features

- View shopping cart items with images and descriptions
- Calculate item totals, tax, and shipping
- Select shipping options (Free, 2-day, Overnight)
- Confirmation modal for purchases
- RESTful API for cart data

## Project Structure

```
├── index.js                 # Express server entry point
├── carts.js                 # Cart API routes (/api/carts/:id)
├── api_endpoint.test.js     # API endpoint tests with Supertest
├── public/                  # Static assets (images, HTML)
└── src/
    ├── App.js               # Main React component
    ├── cartview.js          # Shopping cart display component
    ├── cartItem.js          # Individual cart item (Material-UI Card)
    ├── shippingOptions.js   # Shipping selection radio buttons
    ├── zipcodeEntry.js      # Zipcode input for tax calculation
    ├── msgYNModal.js        # Yes/No confirmation dialog
    ├── sum.js               # Utility function for calculations
    └── *.test.js            # Component test files
```

## Installation

```bash
npm install
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm start` | Start the Express server (serves built React app) |
| `npm run start-node` | Alias for starting the Node server |
| `npm run build-react` | Build the React app for production |
| `npm run test-react` | Run all React component tests with coverage |
| `npm run test-API` | Run API endpoint tests with Supertest |
| `npm test` | Run specific test file (todoTitle.mock.test.js) |

## Testing Techniques Demonstrated

### 1. Component Testing with React Testing Library

Testing React components with mocked fetch calls:

```javascript
// Mock the fetch API
beforeAll(() => jest.spyOn(window, 'fetch'))
window.fetch.mockResolvedValueOnce({
  status: 200,
  ok: true,
  json: async () => ({ cartID: "777", cartItems: [...] }),
})

// Render and assert
render(<App cartId={777} />);
expect(await screen.findByTestId("cart_heading_id")).toBeInTheDocument();
```

### 2. Component Mocking

Replacing child components with simpler test doubles:

```javascript
jest.mock("./cartItem", () => {
  return function DummyCartItem(props) {
    return <div data-testid="dummycartitem">Dummy CartItem</div>;
  };
});
```

### 3. Async Module Mocking (Axios)

Mocking HTTP clients for isolated unit tests:

```javascript
jest.mock('axios');
axios.get.mockResolvedValue({ data: { title: 'Test Data' } });
```

### 4. API Endpoint Testing

Testing Express routes with Supertest:

```javascript
const request = require('supertest')(app);

test("should get a valid cart", function (done) {
  request.get('/api/carts/777')
    .end(function (err, res) {
      assert.strictEqual(res.status, 200);
      done();
    });
});
```

### 5. Re-render Testing

Verifying component updates when props change:

```javascript
const { rerender } = render(<CartView shippingCost={0} cartId={999999} />);
expect(screen.getByText(/^Order Total/)).toHaveTextContent("Order Total: $3.66");

rerender(<CartView shippingCost={500} cartId={999999} />);
expect(screen.getByText(/^Order Total/)).toHaveTextContent("Order Total: $9.16");
```

### 6. User Interaction Testing

Simulating clicks and verifying UI updates:

```javascript
fireEvent.click(screen.getByText('$20.00 overnight shipping'));
expect(screen.getByTestId('radio-button-overnight')).toBeChecked();
```

## Tech Stack

- **React** 17.0.2
- **Material-UI** 4.11.3
- **Express** 4.17.2
- **Jest** (via react-scripts)
- **React Testing Library** 12.1.2
- **Supertest** 6.2.2 (API testing)
- **Axios** 0.26.0

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/carts/:id` | Retrieve cart by ID (777, 888 available) |

## Running the App

1. Build the React frontend:
   ```bash
   npm run build-react
   ```

2. Start the server:
   ```bash
   npm start
   ```

3. Open http://localhost:3000 in your browser

## Running Tests

```bash
# All React tests with coverage report
npm run test-react

# API endpoint tests
npm run test-API
```

Coverage reports are generated in `coverage/lcov-report/index.html`.

## License

See [LICENSE](LICENSE) file.
