import { useEffect, useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { CustomerForm, type CustomerFormValues } from '@/components/CustomerForm';
import { Breadcrumbs } from '@/components/CustomerTable';
import { PageHeader, Panel, PrimaryButton, SecondaryButton, LoadingSpinner } from '@/components/ui';
import { getCustomer, updateCustomer } from '@/lib/customerService';
import type { Customer, CustomerStatus } from '@/types';

function toForm(c: Customer): CustomerFormValues {
  return {
    name: c.name,
    phone: c.phone ?? '',
    source: c.source ?? '',
    product_id: c.product_id ?? '',
    product: c.product ?? '',
    note: c.note ?? '',
    status: c.status,
    warrantyEndDate: c.warranty_end_date
      ? new Date(c.warranty_end_date).toISOString().slice(0, 10)
      : '',
  };
}

export function EditCustomerPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [values, setValues] = useState<CustomerFormValues | null>(null);
  const [original, setOriginal] = useState<Customer | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!id) return;
    getCustomer(Number(id)).then((c) => {
      if (c) {
        setOriginal(c);
        setValues(toForm(c));
      }
    });
  }, [id]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!values || !original?.id) return;
    setSaving(true);
    await updateCustomer({
      ...original,
      name: values.name.trim(),
      phone: values.phone.trim() || null,
      source: values.source || null,
      product_id: values.product_id === '' ? null : values.product_id,
      product: values.product.trim() || null,
      note: values.note.trim() || null,
      status: values.status as CustomerStatus,
      warranty_end_date: values.warrantyEndDate
        ? new Date(values.warrantyEndDate).getTime()
        : null,
    });
    navigate(`/customers/${original.id}`, { replace: true });
  }

  if (!values) return <LoadingSpinner />;

  return (
    <div>
      <Breadcrumbs
        items={[
          { label: 'Khách hàng', to: '/customers' },
          { label: original?.name ?? '...', to: original ? `/customers/${original.id}` : undefined },
          { label: 'Chỉnh sửa' },
        ]}
      />
      <PageHeader title="Chỉnh sửa khách hàng" />

      <div className="max-w-2xl">
        <Panel>
          <form onSubmit={handleSubmit}>
            <CustomerForm values={values} onChange={setValues} />
            <div className="mt-6 flex gap-3 border-t border-slate-200 pt-6 dark:border-slate-800">
              <PrimaryButton type="submit" disabled={saving}>
                {saving ? 'Đang lưu...' : 'Cập nhật'}
              </PrimaryButton>
              <Link to={`/customers/${original?.id}`}>
                <SecondaryButton type="button">Huỷ</SecondaryButton>
              </Link>
            </div>
          </form>
        </Panel>
      </div>
    </div>
  );
}
