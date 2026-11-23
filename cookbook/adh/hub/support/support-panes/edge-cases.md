
- **A lapsed request (MUST)**: a request undecided for seven days shows as ended ("Lapsed"), with no approve button.
- **A grant ending while open (MUST)**: when a viewer read is refused because the grant has ended (403), the viewer says "This grant is no longer live." and offers no next page.
- **Break-glass on a person who is also a customer (MUST)**: the grant keeps the break-glass mark (it follows the grant's `consent`) in every list that shows it.
- **No second factor (MUST)**: a product admin without one is sent by the backend's refusal through the step-up redirect (`/auth/signin` with `prompt=login` and `max_age=600`); what the sign-in does after that, including enrolment, is the sign-in's, not the pane's.

