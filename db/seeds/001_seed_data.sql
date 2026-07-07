WITH orgs AS (
  SELECT ARRAY[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid
  ] AS ids
),
bookings AS (
  INSERT INTO hotel_bookings (
    id,
    org_id,
    hotel_id,
    city,
    checkin_date,
    checkout_date,
    amount,
    status,
    created_at
  )
  SELECT
    gen_random_uuid(),
    (orgs.ids[((gs - 1) % 4) + 1]),
    'hotel-' || LPAD(((gs - 1) % 25 + 1)::text, 3, '0'),
    (ARRAY['delhi', 'mumbai', 'bengaluru', 'hyderabad', 'pune'])[((gs - 1) % 5) + 1],
    CURRENT_DATE + ((gs % 20) + 1),
    CURRENT_DATE + ((gs % 20) + 3),
    ROUND((2500 + (gs * 137.43))::numeric, 2),
    (ARRAY['confirmed', 'cancelled', 'pending', 'completed'])[((gs - 1) % 4) + 1],
    NOW() - ((gs % 45) || ' days')::interval
  FROM generate_series(1, 150) AS gs
  CROSS JOIN orgs
  RETURNING id, status, amount, created_at
),
created_events AS (
  INSERT INTO booking_events (booking_id, event_type, payload, created_at)
  SELECT
    id,
    'booking_created',
    jsonb_build_object('source', 'seed', 'amount', amount),
    created_at
  FROM bookings
  RETURNING booking_id
)
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
  id,
  CASE
    WHEN status = 'cancelled' THEN 'booking_cancelled'
    WHEN status = 'confirmed' THEN 'payment_captured'
    WHEN status = 'completed' THEN 'guest_checked_out'
    ELSE 'booking_pending_review'
  END,
  jsonb_build_object('status', status),
  created_at + INTERVAL '1 hour'
FROM bookings
WHERE status IN ('cancelled', 'confirmed', 'completed')
   OR id IN (SELECT booking_id FROM created_events LIMIT 20);

