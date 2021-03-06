//
//  PhotoBrowserAnimator.swift
//  Weibo10
//
//  Created by male on 15/10/27.
//  Copyright © 2015年 itheima. All rights reserved.
//

import UIKit

// MARK: - 展现动画协议
protocol PhotoBrowserPresentDelegate: NSObjectProtocol {
    
    /// 指定 indexPath 对应的 imageView，用来做动画效果
    func imageViewForPresent(indexPath: IndexPath) -> UIImageView
    
    /// 动画转场的起始位置
    func photoBrowserPresentFromRect(indexPath: IndexPath) -> CGRect
    
    /// 动画转场的目标位置
    func photoBrowserPresentToRect(indexPath: IndexPath) -> CGRect
}

// MARK: - 解除动画协议
protocol PhotoBrowserDismissDelegate: NSObjectProtocol {
    
    /// 解除转场的图像视图（包含起始位置）
    func imageViewForDismiss() -> UIImageView
    /// 解除转场的图像索引
    func indexPathForDismiss() -> IndexPath
}

// MARK: - 提供动画转场的`代理`
class PhotoBrowserAnimator: NSObject, UIViewControllerTransitioningDelegate {

    /// 展现代理
    weak var presentDelegate: PhotoBrowserPresentDelegate?
    /// 解除代理
    weak var dismissDelegate: PhotoBrowserDismissDelegate?
    
    /// 动画图像的索引
    var indexPath: IndexPath?
    
    /// 是否 modal 展现的标记
     var isPresented = false
    
    /// 设置代理相关属性 － 让代码放在合适的位置
    ///
    /// - parameter presentDelegate: 展现代理对象
    /// - parameter indexPath:       图像索引
    func setDelegateParams(presentDelegate: PhotoBrowserPresentDelegate,
        indexPath: IndexPath,
        dismissDelegate: PhotoBrowserDismissDelegate) {
        
            self.presentDelegate = presentDelegate
            self.dismissDelegate = dismissDelegate
            self.indexPath = indexPath
    }
     // 返回提供 modal 展现的`动画的对象`
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
   
        isPresented = true
        
        return self
    }
   
   
    
    // 返回提供 dismiss 的`动画对象`
   
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresented = false
        
        return self
    }
}

// MARK: - UIViewControllerContextTransitioning
// 实现具体的动画方法
extension PhotoBrowserAnimator: UIViewControllerAnimatedTransitioning {
    
    // 动画时长
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 0.6
    }
    
    /// 实现具体的动画效果 - 一旦实现了此方法，所有的动画代码都交由程序员负责
    ///
    /// - parameter transitionContext: 转场动画的上下文 － 提供动画所需要的素材
    /**
        1. 容器视图 － 会将 Modal 要展现的视图包装在容器视图中
            存放的视图要显示－必须自己指定大小！不会通过自动布局填满屏幕
        2. viewControllerForKey: fromVC / toVC
        3. viewForKey: fromView / toView
        4. completeTransition: 无论转场是否被取消，都必须调用
            否则，系统不做其他事件处理！
    */
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // 自动布局系统不会对根视图做任何约束
//        let v = UIView(frame: UIScreen.mainScreen().bounds)
//        v.backgroundColor = UIColor.redColor()
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        
        
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
       
        
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
        
        
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)
       
    
        isPresented ? presentAnimation(transitionContext: transitionContext) : dismissAnimation(transitionContext: transitionContext)
    }
    
    /// 解除转场动画
    private func dismissAnimation(transitionContext: UIViewControllerContextTransitioning) {

        // guard let 会把属性变成局部变量，后续的闭包中不需要 self，也不需要考虑解包！
        guard let presentDelegate = presentDelegate,
            let dismissDelegate = dismissDelegate else {
                return
        }
        
        // 1. 获取要 dismiss 的控制器的视图
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        fromView.removeFromSuperview()
        
        // 2. 获取图像视图
        let iv = dismissDelegate.imageViewForDismiss()
        // 添加到容器视图
        transitionContext.containerView.addSubview(iv)
        
        // 3. 获取dismiss的indexPath
        let indexPath = dismissDelegate.indexPathForDismiss()
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
            animations: { () -> Void in
               
                // 让 iv 运动到目标位置
                if indexPath.row <= 2 {
                iv.frame = presentDelegate.photoBrowserPresentFromRect(indexPath: indexPath)
                }
                
            }) { (_) -> Void in
                
                // 将 iv 从父视图中删除
                iv.removeFromSuperview()
                
                // 告诉系统动画完成
                transitionContext.completeTransition(true)
        }
    }
    
    /// 展现动画
    private func presentAnimation(transitionContext: UIViewControllerContextTransitioning) {
  
        // 判断参数是否存在
        guard let presentDelegate = presentDelegate, let indexPath = indexPath else {
            return
        }
       
        // 1. 目标视图
        // 1> 获取 modal 要展现的控制器的根视图
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        // 2> 将视图添加到容器视图中
        transitionContext.containerView.addSubview(toView)
        
        // 2. 获取目标控制器 - 照片查看控制器
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as! PhotoBrowserViewController
        // 隐藏 collectionView
        toVC.collectionView.isHidden = true
        
        // 3. 图像视图
        let iv = presentDelegate.imageViewForPresent(indexPath: indexPath)
        // 1> 指定图像视图位置
        iv.frame = presentDelegate.photoBrowserPresentFromRect(indexPath: indexPath)
        
        // 2> 将图像视图添加到容器视图
        transitionContext.containerView.addSubview(iv)
        
       // toView.alpha = 0
       toView.backgroundColor = UIColor.clear
        // 4. 开始动画
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
            animations: { () -> Void in
         toView.backgroundColor = BLACK_COLOR
                iv.frame = presentDelegate.photoBrowserPresentToRect(indexPath: indexPath)
              //  toView.alpha = 1
                
            }) { (_) -> Void in
                
                // 将图像视图删除
                iv.removeFromSuperview()
                
                // 显示目标视图控制器的 collectioView
                toVC.collectionView.isHidden = false
                
                // 告诉系统转场动画完成
                transitionContext.completeTransition(true)
        }
    }
}
