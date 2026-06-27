import { Routes, Route } from 'react-router-dom';
import { Layout } from '@/components/Layout';
import { HomePage } from '@/pages/HomePage';
import { AllCustomersPage } from '@/pages/AllCustomersPage';
import { ProductsPage } from '@/pages/ProductsPage';
import { OrdersPage } from '@/pages/OrdersPage';
import { AddOrderPage } from '@/pages/AddOrderPage';
import { StatsPage } from '@/pages/StatsPage';
import { SettingsPage } from '@/pages/SettingsPage';
import { GuidePage } from '@/pages/GuidePage';
import { AddCustomerPage } from '@/pages/AddCustomerPage';
import { EditCustomerPage } from '@/pages/EditCustomerPage';
import { CustomerDetailPage } from '@/pages/CustomerDetailPage';
import { DebtsPage } from '@/pages/DebtsPage';

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<HomePage />} />
        <Route path="customers" element={<AllCustomersPage />} />
        <Route path="customers/new" element={<AddCustomerPage />} />
        <Route path="customers/:id" element={<CustomerDetailPage />} />
        <Route path="customers/:id/edit" element={<EditCustomerPage />} />
        <Route path="products" element={<ProductsPage />} />
        <Route path="orders" element={<OrdersPage />} />
        <Route path="orders/new" element={<AddOrderPage />} />
        <Route path="debts" element={<DebtsPage />} />
        <Route path="stats" element={<StatsPage />} />
        <Route path="guide" element={<GuidePage />} />
        <Route path="settings" element={<SettingsPage />} />
      </Route>
    </Routes>
  );
}
