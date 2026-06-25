import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams, Link } from 'react-router-dom';
import type { Customer } from '@/types';
import { Breadcrumbs } from '@/components/CustomerTable';
import { OrderForm } from '@/components/OrderForm';
import { CustomerPicker } from '@/components/CustomerPicker';
import { PageHeader, Panel, LoadingSpinner } from '@/components/ui';
import { getAllCustomers, getCustomer } from '@/lib/customerService';

export function AddOrderPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const preCustomerId = searchParams.get('customerId');
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [selectedId, setSelectedId] = useState<number | ''>(
    preCustomerId ? Number(preCustomerId) : '',
  );
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAllCustomers().then((list) => {
      setCustomers(list);
      setLoading(false);
    });
  }, []);

  useEffect(() => {
    if (selectedId === '') {
      setCustomer(null);
      return;
    }
    getCustomer(selectedId).then(setCustomer);
  }, [selectedId]);

  if (loading) return <LoadingSpinner />;

  return (
    <div>
      <Breadcrumbs
        items={[
          { label: 'Đơn hàng', to: '/orders' },
          { label: 'Ghi đơn mới' },
        ]}
      />

      <PageHeader title="Ghi đơn mới" subtitle="Ghi nhận doanh thu, lợi nhuận và hoa hồng" />

      <div className="max-w-2xl">
        <Panel>
          <div className="mb-6">
            <CustomerPicker
              customers={customers}
              value={selectedId}
              onChange={setSelectedId}
            />
            {customers.length === 0 && (
              <p className="mt-2 text-sm text-slate-500">
                Chưa có khách.{' '}
                <Link to="/customers/new" className="text-brand-600 hover:underline">
                  Thêm khách trước
                </Link>
              </p>
            )}
          </div>

          {customer ? (
            <OrderForm
              customer={customer}
              onSuccess={() => navigate(`/customers/${customer.id}`, { replace: true })}
              onCancel={() => navigate(-1)}
            />
          ) : (
            <p className="text-center text-sm text-slate-500">
              Chọn khách hàng để tiếp tục ghi đơn.
            </p>
          )}
        </Panel>
      </div>
    </div>
  );
}
