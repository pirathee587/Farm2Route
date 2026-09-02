-- V15__create_finance_tables.sql
-- Financial Management: Bank Details, Transactions, and Withdrawals

CREATE TABLE IF NOT EXISTS bank_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bank_name VARCHAR(100) NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    account_holder_name VARCHAR(150) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_user ON bank_details(user_id);

CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    payer_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    payee_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    commission_deducted DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    net_amount DECIMAL(10, 2) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- BOOKING_PAYMENT, COMMISSION_DEDUCTION, AGENCY_PAYOUT, REFUND
    payment_method VARCHAR(50) NOT NULL DEFAULT 'IN_APP_WALLET', -- CARD, BANK_TRANSFER, CASH_ON_DELIVERY, IN_APP_WALLET
    status VARCHAR(30) NOT NULL DEFAULT 'COMPLETED', -- PENDING, COMPLETED, FAILED, REFUNDED
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tx_booking ON transactions(booking_id);
CREATE INDEX idx_tx_payer ON transactions(payer_user_id);
CREATE INDEX idx_tx_payee ON transactions(payee_user_id);
CREATE INDEX idx_tx_status ON transactions(status);

CREATE TABLE IF NOT EXISTS withdrawals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bank_detail_id UUID NOT NULL REFERENCES bank_details(id) ON DELETE RESTRICT,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, PROCESSED, REJECTED
    admin_notes TEXT,
    processed_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_withdrawals_user ON withdrawals(user_id);
CREATE INDEX idx_withdrawals_status ON withdrawals(status);
