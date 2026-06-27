import { db, monthRangeFromDate } from './db';
import type { Expense, ExpenseCategory } from '@/types';

export async function getExpensesForMonth(date = new Date()): Promise<Expense[]> {
  const { start, end } = monthRangeFromDate(date);
  return db.expenses
    .where('created_at')
    .between(start, end, true, false)
    .reverse()
    .sortBy('created_at');
}

export async function getExpensesTotalForMonth(date = new Date()): Promise<number> {
  const list = await getExpensesForMonth(date);
  return list.reduce((sum, e) => sum + e.amount, 0);
}

export async function getTrueProfit(grossProfit: number, date = new Date()): Promise<number> {
  const expenses = await getExpensesTotalForMonth(date);
  return grossProfit - expenses;
}

export async function addExpense(input: {
  category: ExpenseCategory;
  amount: number;
  note?: string;
  created_at?: number;
}): Promise<Expense> {
  const expense: Expense = {
    category: input.category,
    amount: input.amount,
    note: input.note?.trim() || null,
    created_at: input.created_at ?? Date.now(),
  };
  const id = await db.expenses.add(expense);
  return { ...expense, id };
}

export async function deleteExpense(id: number): Promise<void> {
  await db.expenses.delete(id);
}
