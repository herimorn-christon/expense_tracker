<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Expense;
use App\Models\User;
use Carbon\Carbon;

class ExpenseSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::all();

        foreach ($users as $user) {
            $categories = \App\Models\Category::where('user_id', $user->id)->get();

            if ($categories->isEmpty()) {
                continue;
            }

            // Sample expenses for the current month
            $expenses = [
                [
                    'title' => 'Grocery Shopping',
                    'description' => 'Weekly groceries at local supermarket',
                    'amount' => 85.50,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'SuperMart Downtown',
                    'category_id' => $categories->where('name', 'Food & Dining')->first()->id,
                ],
                [
                    'title' => 'Gas Station',
                    'description' => 'Fuel for car',
                    'amount' => 45.00,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'Shell Station',
                    'category_id' => $categories->where('name', 'Transportation')->first()->id,
                ],
                [
                    'title' => 'Netflix Subscription',
                    'description' => 'Monthly streaming subscription',
                    'amount' => 15.99,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'Online',
                    'category_id' => $categories->where('name', 'Entertainment')->first()->id,
                ],
                [
                    'title' => 'Coffee Shop',
                    'description' => 'Morning coffee and pastry',
                    'amount' => 12.75,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'cash',
                    'location' => 'Downtown Cafe',
                    'category_id' => $categories->where('name', 'Food & Dining')->first()->id,
                ],
                [
                    'title' => 'Electricity Bill',
                    'description' => 'Monthly electricity bill',
                    'amount' => 120.00,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'bank_transfer',
                    'location' => 'Online Banking',
                    'category_id' => $categories->where('name', 'Bills & Utilities')->first()->id,
                ],
                [
                    'title' => 'New Headphones',
                    'description' => 'Wireless headphones for work',
                    'amount' => 199.99,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'Electronics Store',
                    'category_id' => $categories->where('name', 'Shopping')->first()->id,
                ],
                [
                    'title' => 'Uber Ride',
                    'description' => 'Ride to airport',
                    'amount' => 25.50,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'Uber App',
                    'category_id' => $categories->where('name', 'Transportation')->first()->id,
                ],
                [
                    'title' => 'Pharmacy',
                    'description' => 'Prescription medication',
                    'amount' => 35.25,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'Local Pharmacy',
                    'category_id' => $categories->where('name', 'Healthcare')->first()->id,
                ],
                [
                    'title' => 'Movie Tickets',
                    'description' => 'Cinema tickets for weekend',
                    'amount' => 28.00,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'card',
                    'location' => 'Cinema Complex',
                    'category_id' => $categories->where('name', 'Entertainment')->first()->id,
                ],
                [
                    'title' => 'Internet Bill',
                    'description' => 'Monthly internet service',
                    'amount' => 79.99,
                    'expense_date' => Carbon::now()->subDays(rand(1, 30)),
                    'payment_method' => 'bank_transfer',
                    'location' => 'Online',
                    'category_id' => $categories->where('name', 'Bills & Utilities')->first()->id,
                ],
            ];

            foreach ($expenses as $expenseData) {
                Expense::create([
                    'user_id' => $user->id,
                    'category_id' => $expenseData['category_id'],
                    'title' => $expenseData['title'],
                    'description' => $expenseData['description'],
                    'amount' => $expenseData['amount'],
                    'expense_date' => $expenseData['expense_date'],
                    'payment_method' => $expenseData['payment_method'],
                    'location' => $expenseData['location'],
                ]);
            }
        }
    }
}
