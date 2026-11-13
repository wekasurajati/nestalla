<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require_once __DIR__ . '/../PHPMailer/src/Exception.php';
require_once __DIR__ . '/../PHPMailer/src/PHPMailer.php';
require_once __DIR__ . '/../PHPMailer/src/SMTP.php';

class EmailService {
    private $mailer;
    
    public function __construct() {
        $this->mailer = new PHPMailer(true);
        
        try {
            // SMTP Configuration
            $this->mailer->isSMTP();
            $this->mailer->Host = 'sandbox.smtp.mailtrap.io';
            $this->mailer->SMTPAuth = true;
            $this->mailer->Username = 'ISI SENDIRI'; 
            $this->mailer->Password = 'ISI SENDIRI'; 
            $this->mailer->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $this->mailer->Port = 2525;
            
            // Sender info
            $this->mailer->setFrom('noreply@letterbook.com', 'Letterbook');
            $this->mailer->isHTML(true);
            
        } catch (Exception $e) {
            error_log("Email configuration error: " . $e->getMessage());
        }
    }
    
    // Send welcome email
    public function sendWelcomeEmail($to_email, $to_name) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($to_email, $to_name);
            
            $this->mailer->Subject = 'Welcome to Nestalla! 📚';
            $this->mailer->Body = $this->getWelcomeTemplate($to_name);
            
            return $this->mailer->send();
        } catch (Exception $e) {
            error_log("Failed to send welcome email: " . $e->getMessage());
            return false;
        }
    }
    
    // Send order confirmation
    public function sendOrderConfirmation($to_email, $to_name, $order_number, $total_amount, $items) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($to_email, $to_name);
            
            $this->mailer->Subject = 'Order Confirmation - ' . $order_number;
            $this->mailer->Body = $this->getOrderTemplate($to_name, $order_number, $total_amount, $items);
            
            return $this->mailer->send();
        } catch (Exception $e) {
            error_log("Failed to send order confirmation: " . $e->getMessage());
            return false;
        }
    }
    
    // Send order status update
    public function sendOrderStatusUpdate($to_email, $to_name, $order_number, $status) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($to_email, $to_name);
            
            $status_messages = [
                'processing' => 'Your order is being processed',
                'shipped' => 'Your order has been shipped!',
                'completed' => 'Your order is completed!',
                'cancelled' => 'Your order has been cancelled'
            ];
            
            $this->mailer->Subject = 'Order Update - ' . $order_number;
            $this->mailer->Body = $this->getStatusUpdateTemplate($to_name, $order_number, $status, $status_messages[$status]);
            
            return $this->mailer->send();
        } catch (Exception $e) {
            error_log("Failed to send status update: " . $e->getMessage());
            return false;
        }
    }
    
    // Send password changed notification
    public function sendPasswordChangedEmail($to_email, $to_name) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($to_email, $to_name);
            
            $this->mailer->Subject = 'Password Changed - Letterbook';
            $this->mailer->Body = $this->getPasswordChangedTemplate($to_name);
            
            return $this->mailer->send();
        } catch (Exception $e) {
            error_log("Failed to send password changed email: " . $e->getMessage());
            return false;
        }
    }
    
    // Email Templates
    private function getWelcomeTemplate($name) {
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #ee6c8d, #ff6b9d); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .button { display: inline-block; background: #ee6c8d; color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; margin-top: 20px; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>Welcome to Letterbook!</h1>
                </div>
                <div class='content'>
                    <h2>Hi $name,</h2>
                    <p>Thank you for joining Letterbook! We're excited to have you as part of our reading community.</p>
                    <p>Start exploring our collection of amazing books and enjoy your reading journey with us!</p>
                    <a href='http://localhost/letterbook/index.html' class='button'>Start Shopping</a>
                    <p style='margin-top: 30px;'>Happy reading!</p>
                </div>
                <div class='footer'>
                    <p>&copy; 2024 Letterbook. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        ";
    }
    
    private function getOrderTemplate($name, $order_number, $total, $items) {
        $items_html = '';
        foreach ($items as $item) {
            $items_html .= "<tr>
                <td style='padding: 10px; border-bottom: 1px solid #ddd;'>{$item['title']}</td>
                <td style='padding: 10px; border-bottom: 1px solid #ddd; text-align: center;'>{$item['quantity']}</td>
                <td style='padding: 10px; border-bottom: 1px solid #ddd; text-align: right;'>Rp" . number_format($item['price'], 0, ',', '.') . "</td>
            </tr>";
        }
        
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #ee6c8d, #ff6b9d); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; }
                .order-box { background: white; padding: 20px; border-radius: 10px; margin: 20px 0; }
                table { width: 100%; border-collapse: collapse; }
                .total { font-size: 20px; font-weight: bold; color: #ee6c8d; text-align: right; margin-top: 20px; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>Order Confirmed</h1>
                </div>
                <div class='content'>
                    <h2>Hi $name,</h2>
                    <p>Thank you for your order! We've received your order and will process it soon.</p>
                    
                    <div class='order-box'>
                        <h3>Order Details</h3>
                        <p><strong>Order Number:</strong> $order_number</p>
                        
                        <table>
                            <thead>
                                <tr style='background: #f0f0f0;'>
                                    <th style='padding: 10px; text-align: left;'>Item</th>
                                    <th style='padding: 10px; text-align: center;'>Qty</th>
                                    <th style='padding: 10px; text-align: right;'>Price</th>
                                </tr>
                            </thead>
                            <tbody>
                                $items_html
                            </tbody>
                        </table>
                        
                        <div class='total'>
                            Total: Rp" . number_format($total, 0, ',', '.') . "
                        </div>
                    </div>
                    
                    <p>We'll send you another email when your order is shipped.</p>
                </div>
                <div class='footer'>
                    <p>&copy; 2024 Letterbook. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        ";
    }
    
    private function getStatusUpdateTemplate($name, $order_number, $status, $message) {
    // Status styling
    $status_config = [
        'pending' => [
            
            'color' => '#ffc107',
            'bg' => '#fff3cd',
            'title' => 'Order Pending'
        ],
        'processing' => [
            
            'color' => '#17a2b8',
            'bg' => '#d1ecf1',
            'title' => 'Processing Your Order'
        ],
        'shipped' => [
            
            'color' => '#007bff',
            'bg' => '#cce5ff',
            'title' => 'Order Shipped!'
        ],
        'completed' => [
            'emoji' => '✅',
            'color' => '#28a745',
            'bg' => '#d4edda',
            'title' => 'Order Completed!'
        ],
        'cancelled' => [
            
            'color' => '#dc3545',
            'bg' => '#f8d7da',
            'title' => 'Order Cancelled'
        ]
    ];
    
    $config = $status_config[$status] ?? $status_config['processing'];
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Order Update - Letterbook</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                padding: 40px 20px;
            }
            .email-container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                border-radius: 20px;
                overflow: hidden;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            }
            .header {
                background: linear-gradient(135deg, #ee6c8d 0%, #ff6b9d 100%);
                padding: 40px 30px;
                text-align: center;
                color: white;
            }
            .header h1 {
                font-size: 28px;
                font-weight: 600;
                margin-bottom: 10px;
                text-shadow: 0 2px 4px rgba(0,0,0,0.1);
                text-align: center;
            }
            .header .logo {
                font-size: 40px;
                margin-bottom: 10px;
            }
            .content {
                padding: 40px 30px;
            }
            .greeting {
                font-size: 24px;
                color: #333;
                margin-bottom: 20px;
                font-weight: 600;
            }
            .status-card {
                background: {$config['bg']};
                border-left: 5px solid {$config['color']};
                padding: 25px;
                border-radius: 10px;
                margin: 30px 0;
                text-align: center;
            }
            .status-emoji {
                font-size: 60px;
                margin-bottom: 15px;
                display: block;
            }
            .status-title {
                font-size: 22px;
                font-weight: 700;
                color: {$config['color']};
                margin-bottom: 10px;
            }
            .status-message {
                font-size: 16px;
                color: #555;
                margin-bottom: 15px;
            }
            .order-info {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
            }
            .order-info-row {
                display: flex;
                justify-content: space-between;
                padding: 12px 0;
                border-bottom: 1px dashed #dee2e6;
            }
            .order-info-row:last-child {
                border-bottom: none;
            }
            .order-info-label {
                font-weight: 600;
                color: #666;
            }
            .order-info-value {
                color: #333;
                font-weight: 700;
            }
            .timeline {
                margin: 30px 0;
                padding: 20px;
                background: #f8f9fa;
                border-radius: 10px;
            }
            .timeline-title {
                font-size: 18px;
                font-weight: 600;
                color: #333;
                margin-bottom: 15px;
                text-align: center;
            }
            .timeline-item {
                display: flex;
                align-items: center;
                padding: 10px 0;
                position: relative;
            }
            .timeline-dot {
                width: 12px;
                height: 12px;
                border-radius: 50%;
                background: #dee2e6;
                margin-right: 15px;
                position: relative;
                z-index: 1;
            }
            .timeline-dot.active {
                background: {$config['color']};
                box-shadow: 0 0 0 4px {$config['bg']};
            }
            .timeline-text {
                font-size: 14px;
                color: #666;
            }
            .timeline-text.active {
                color: #333;
                font-weight: 600;
            }
            .cta-button {
                display: inline-block;
                background: linear-gradient(135deg, #ee6c8d 0%, #ff6b9d 100%);
                color: white;
                padding: 15px 40px;
                text-decoration: none;
                border-radius: 50px;
                font-weight: 600;
                font-size: 16px;
                margin: 20px 0;
                box-shadow: 0 5px 15px rgba(238, 108, 141, 0.3);
                transition: transform 0.3s ease;
            }
            .cta-button:hover {
                transform: translateY(-2px);
                box-shadow: 0 7px 20px rgba(238, 108, 141, 0.4);
            }
            .divider {
                height: 1px;
                background: linear-gradient(to right, transparent, #dee2e6, transparent);
                margin: 30px 0;
            }
            .footer {
                background: #f8f9fa;
                padding: 30px;
                text-align: center;
                color: #666;
                font-size: 14px;
            }
            .footer-links {
                margin: 15px 0;
            }
            .footer-links a {
                color: #ee6c8d;
                text-decoration: none;
                margin: 0 10px;
            }
            .social-links {
                margin: 20px 0;
            }
            .social-links a {
                display: inline-block;
                width: 40px;
                height: 40px;
                background: #ee6c8d;
                color: white;
                border-radius: 50%;
                line-height: 40px;
                margin: 0 5px;
                text-decoration: none;
                font-size: 18px;
            }
            @media only screen and (max-width: 600px) {
                .email-container { border-radius: 0; }
                .content { padding: 30px 20px; }
                .header { padding: 30px 20px; }
                .greeting { font-size: 20px; }
                .status-title { font-size: 18px; }
            }
        </style>
    </head>
    <body>
        <div class='email-container'>
            <!-- Header -->
            <div class='header'>
                <div class='logo'></div>
                <h1>Letterbook</h1>
                <p style='font-size: 14px; opacity: 0.9;'>Your Digital Library</p>
            </div>
            
            <!-- Content -->
            <div class='content'>
                <div class='greeting'>Hi $name! </div>
                
                <!-- Status Card -->
                <div class='status-card'>
                    <span class='status-emoji'>{$config['emoji']}</span>
                    <div class='status-title'>{$config['title']}</div>
                    <div class='status-message'>$message</div>
                </div>
                
                <!-- Order Info -->
                <div class='order-info'>
                    <div class='order-info-row'>
                        <span class='order-info-label'>Order Number</span>
                        <span class='order-info-value'>$order_number</span>
                    </div>
                    <div class='order-info-row'>
                        <span class='order-info-label'>Current Status</span>
                        <span class='order-info-value' style='color: {$config['color']};'>" . ucfirst($status) . "</span>
                    </div>
                    <div class='order-info-row'>
                        <span class='order-info-label'>Updated</span>
                        <span class='order-info-value'>" . date('M d, Y - H:i') . "</span>
                    </div>
                </div>
                
                <!-- Timeline -->
                <div class='timeline'>
                    <div class='timeline-title'>Order Progress</div>
                    <div class='timeline-item'>
                        <div class='timeline-dot active'></div>
                        <div class='timeline-text active'>Order Placed</div>
                    </div>
                    <div class='timeline-item'>
                        <div class='timeline-dot " . ($status == 'processing' || $status == 'shipped' || $status == 'completed' ? 'active' : '') . "'></div>
                        <div class='timeline-text " . ($status == 'processing' || $status == 'shipped' || $status == 'completed' ? 'active' : '') . "'>Processing</div>
                    </div>
                    <div class='timeline-item'>
                        <div class='timeline-dot " . ($status == 'shipped' || $status == 'completed' ? 'active' : '') . "'></div>
                        <div class='timeline-text " . ($status == 'shipped' || $status == 'completed' ? 'active' : '') . "'>Shipped</div>
                    </div>
                    <div class='timeline-item'>
                        <div class='timeline-dot " . ($status == 'completed' ? 'active' : '') . "'></div>
                        <div class='timeline-text " . ($status == 'completed' ? 'active' : '') . "'>Completed</div>
                    </div>
                </div>
                
                <div class='divider'></div>
                
                <!-- CTA Button -->
                <div style='text-align: center;'>
                    <a href='http://localhost/letterbook/orders.html' class='cta-button'>
                        View Order Details
                    </a>
                </div>
                
                <p style='text-align: center; color: #666; font-size: 14px; margin-top: 20px;'>
                    Need help? Contact us at <a href='mailto:support@letterbook.com' style='color: #ee6c8d; text-decoration: none;'>support@letterbook.com</a>
                </p>
            </div>
            
            <!-- Footer -->
            <div class='footer'>
                <div class='social-links'>
                    <a href='#'></a>
                    <a href='#'></a>
                    <a href='#'></a>
                </div>
                
                <div class='footer-links'>
                    <a href='#'>About Us</a> 
                    <a href='#'>FAQs</a> 
                    <a href='#'>Contact</a>
                </div>
                
                <p style='margin-top: 15px;'>
                    <strong>Letterbook</strong><br>
                    UNESA Ketintang Campus<br>
                    Surabaya, East Java, Indonesia
                </p>
                
                <p style='margin-top: 15px; font-size: 12px; color: #999;'>
                     2025 Letterbook. All rights reserved.<br>
                    You're receiving this email because you placed an order with us.
                </p>
            </div>
        </div>
    </body>
    </html>
    ";
}
    
    private function getPasswordChangedTemplate($name) {
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #ee6c8d, #ff6b9d); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .warning-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1> Password Changed</h1>
                </div>
                <div class='content'>
                    <h2>Hi $name,</h2>
                    <p>Your password has been successfully changed.</p>
                    
                    <div class='warning-box'>
                        <strong> Security Notice:</strong><br>
                        If you didn't make this change, please contact us immediately.
                    </div>
                    
                    <p>Your account security is important to us.</p>
                </div>
                <div class='footer'>
                    <p>&copy; 2024 Letterbook. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        ";
    }

}
?>
