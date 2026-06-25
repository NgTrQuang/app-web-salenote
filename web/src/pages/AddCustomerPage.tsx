import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { CustomerForm, type CustomerFormValues } from '@/components/CustomerForm';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel, PrimaryButton, SecondaryButton } from '@/components/ui';
import { addCustomer } from '@/lib/customerService';

const initial: CustomerFormValues = {
  name: '',
  phone: '',
  address: '',
  source: '',
  product_id: '',
  product: '',
  note: '',
  status: 'new',
  warrantyEndDate: '',
};

export function AddCustomerPage() {
  const navigate = useNavigate();
  const [values, setValues] = useState<CustomerFormValues>(initial);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!values.name.trim()) {
      setError('Vui lòng nhập tên khách');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const customer = await addCustomer({
        name: values.name,
        phone: values.phone || undefined,
        address: values.address || undefined,
        source: values.source || null,
        product_id: values.product_id === '' ? null : values.product_id,
        product: values.product || undefined,
        note: values.note || undefined,
        status: values.status,
        warrantyEndDate: values.warrantyEndDate
          ? new Date(values.warrantyEndDate)
          : undefined,
      });
      navigate(`/customers/${customer.id}`, { replace: true });
    } catch {
      setError('Không thể lưu khách hàng');
      setSaving(false);
    }
  }

  return (
    <div>
      <Breadcrumbs
        items={[
          { label: 'Khách hàng', to: '/customers' },
          { label: 'Thêm mới' },
        ]}
      />
      <PageHeader
        title="Thêm khách mới"
        subtitle="Ghi nguồn và SP quan tâm — liên kết với danh mục để ghi đơn nhanh"
      />

      <div className="max-w-2xl">
        <Panel>
          <form onSubmit={handleSubmit}>
            <CustomerForm values={values} onChange={setValues} />
            {error && <p className="mt-4 text-sm text-red-600">{error}</p>}
            <div className="mt-6 flex gap-3 border-t border-slate-200 pt-6 dark:border-slate-800">
              <PrimaryButton type="submit" disabled={saving}>
                {saving ? 'Đang lưu...' : 'Lưu khách'}
              </PrimaryButton>
              <Link to="/customers">
                <SecondaryButton type="button">Huỷ</SecondaryButton>
              </Link>
            </div>
          </form>
        </Panel>
      </div>
    </div>
  );
}
