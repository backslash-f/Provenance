//
//  PVGameLibraryViewController+CollectionView.swift
//  Provenance
//
//  Created by Joseph Mattiello on 5/26/18.
//  Copyright © 2018 Provenance. All rights reserved.
//

import Foundation
import PVLibrary
import PVSupport
import RxCocoa
import RxSwift
#if canImport(RxGesture)
    import RxGesture
#endif

// tvOS
let tvOSCellUnit: CGFloat = 256.0

extension PVGameLibraryViewController {
    //	func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    //		if let focusedIndexPath = context.nextFocusedIndexPath {
    //			let section = focusedIndexPath.section
    //			// Fix scroll offset off for special sections
    //			if section == recentGamesSection || section == favoritesSection || section == saveStateSection {
    //				coordinator.addCoordinatedAnimations({
    //					collectionView.scrollToItem(at: focusedIndexPath,
    //												at: .centeredVertically,
    //												animated: true)
    //				}, completion: nil)
    //			}
    //		}
    //	}
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PVGameLibraryViewController: UICollectionViewDelegateFlowLayout {
    var minimumInteritemSpacing: CGFloat {
        #if os(tvOS)
            return 24.0
        #else
            return 10.0
        #endif
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        #if os(tvOS)
            return tvos_collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        #else
            return ios_collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        #endif
    }

    #if os(iOS)
        private func ios_collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            var height: CGFloat = PVSettingsModel.shared.showGameTitles ? 144 : 100
            let viewWidth = transitioningToSize?.width ?? collectionView.bounds.size.width
            let itemsPerRow: CGFloat = viewWidth > 800 ? 6 : 3

            var width: CGFloat = (viewWidth / itemsPerRow) - (minimumInteritemSpacing * itemsPerRow * 0.67)

            let item: Section.Item = try! collectionView.rx.model(at: indexPath)
            switch item {
            case .game:
                width *= collectionViewZoom
                height *= collectionViewZoom
            case .saves, .favorites, .recents:
                // TODO: Multirow?
                let numberOfRows = 1
                width = viewWidth
                height = (height + PageIndicatorHeight + 24) * CGFloat(numberOfRows)
            }
            return .init(width: width, height: height)
        }
    #endif

    #if os(tvOS)
        private func tvos_collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let item: Section.Item = try! collectionView.rx.model(at: indexPath)
            switch item {
            case .game(let game):
                let boxartSize = CGSize(width: tvOSCellUnit, height: tvOSCellUnit / game.boxartAspectRatio.rawValue)
                return PVGameLibraryCollectionViewCell.cellSize(forImageSize: boxartSize)
            case .saves:
            // TODO: Multirow?
                let numberOfRows: CGFloat = 1.0
                let width = viewWidth - collectionView.contentInset.left - collectionView.contentInset.right / 4
                let height = tvOSCellUnit * numberOfRows + PageIndicatorHeight
                return PVSaveStateCollectionViewCell.cellSize(forImageSize: CGSize(width: width, height: height))
            }
            if searchResults != nil {
                return CGSize(width: tvOSCellUnit, height: tvOSCellUnit)
            }

            let viewWidth = transitioningToSize?.width ?? collectionView.bounds.size.width
            if indexPath.section == saveStateSection {
            }

            if indexPath.section == recentGamesSection || indexPath.section == favoritesSection {
                let numberOfRows: CGFloat = 1.0
                let width = viewWidth - collectionView.contentInset.left - collectionView.contentInset.right / 5
                let height: CGFloat = tvOSCellUnit * numberOfRows + PageIndicatorHeight
                return PVSaveStateCollectionViewCell.cellSize(forImageSize: CGSize(width: width, height: height))
//            return PVGameLibraryCollectionViewCell.cellSize(forImageSize: CGSize(width: width, height: height / PVGameBoxArtAspectRatio.tall.rawValue))
            }

            if let game = self.game(at: indexPath, location: .zero) {
                let boxartSize = CGSize(width: tvOSCellUnit, height: tvOSCellUnit / game.boxartAspectRatio.rawValue)
                return PVGameLibraryCollectionViewCell.cellSize(forImageSize: boxartSize)
            } else {
                return PVGameLibraryCollectionViewCell.cellSize(forImageSize: CGSize(width: tvOSCellUnit, height: tvOSCellUnit))
            }
        }
    #endif

    #if os(tvOS)
        func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            let item: Section.Item = try! collectionView.rx.model(at: indexPath)
            switch item {
            case .game(let game):
                return 88
            }
            if section == recentGamesSection || section == favoritesSection || section == saveStateSection {
                return 0
            } else {
                return 88
            }
        }
    #endif

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let item: Section.Item? = firstModel(in: collectionView, at: section)
        switch item {
        case .none:
            return .zero
        case .some(.game):
            return minimumInteritemSpacing
        case .saves, .favorites, .recents:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        #if os(tvOS)
            return UIEdgeInsets(top: 32, left: 0, bottom: 64, right: 0)
        #else
        let item: Section.Item? = firstModel(in: collectionView, at: section)
        switch item {
        case .none:
            return .zero
        case .some(.game):
            return .init(top: section == 0 ? 5 : 15, left: 10, bottom: 5, right: 10)
        case .saves, .favorites, .recents:
            return .zero
        }
        #endif
    }

    private func firstModel(in collectionView: UICollectionView, at section: Int) -> Section.Item? {
        guard collectionView.numberOfItems(inSection: section) > 0 else { return nil }
        return try? collectionView.rx.model(at: IndexPath(item: 0, section: section))
    }
}

// MARK: - UICollectionViewDataSource
/*
extension PVGameLibraryViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in _: UICollectionView) -> Int {
        if searchResults != nil {
            return 1
        } else {
            let count = systemsSectionOffset + (filteredSystems?.count ?? 0)
            VLOG("Sections : \(count)")
            return count
        }
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let searchResults = searchResults {
            return Int(searchResults.count)
        } else {
            if section >= systemsSectionOffset {
                let sectionNumber = section - systemsSectionOffset
                if let system = filteredSystems?[sectionNumber], let token = systemSectionsTokens[system.identifier] {
                    return token.itemsCount
                } else {
                    return 0
                }
            } else if section == favoritesSection {
                return 1
            } else if section == saveStateSection {
                return 1
            } else if section == recentGamesSection {
                return 1
            } else {
                fatalError("Shouldn't be here")
            }
        }
    }

    func indexTitles(for _: UICollectionView) -> [String]? {
        if searchResults != nil {
            return nil
        } else {
            return sectionTitles
        }
    }

    func collectionView(_: UICollectionView, indexPathForIndexTitle _: String, at index: Int) -> IndexPath {
        return IndexPath(row: 0, section: index)
    }

    func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let searchResults = searchResults {
            guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: PVGameLibraryCollectionViewCellIdentifier, for: indexPath) as? PVGameLibraryCollectionViewCell else {
                fatalError("Couldn't create cell of type PVGameLibraryCollectionViewCellIdentifier")
            }
            let game = searchResults[indexPath.item]
            cell.game = game
            cell.delegate = self

            return cell
        }

        if indexPath.section == favoritesSection {
            guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: PVGameLibraryCollectionViewFavoritesCellIdentifier, for: indexPath) as? FavoritesPlayedCollectionCell else {
                fatalError("Couldn't create cell of type PVGameLibraryCollectionViewFavoritesCellIdentifier")
            }

            cell.selectionDelegate = self

            return cell
        }

        if indexPath.section == saveStateSection {
            guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: PVGameLibraryCollectionViewSaveStatesCellIdentifier, for: indexPath) as? SaveStatesCollectionCell else {
                fatalError("Couldn't create cell of type PVGameLibraryCollectionViewSaveStatesCellIdentifier")
            }

            cell.selectionDelegate = self

            return cell
        }

        if indexPath.section == recentGamesSection {
            guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: PVGameLibraryCollectionViewRecentlyPlayedCellIdentifier, for: indexPath) as? RecentlyPlayedCollectionCell else {
                fatalError("Couldn't create cell of type PVGameLibraryCollectionViewRecentlyPlayedCellIdentifier")
            }

            cell.selectionDelegate = self

            return cell
        }

        guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: PVGameLibraryCollectionViewCellIdentifier, for: indexPath) as? PVGameLibraryCollectionViewCell else {
            fatalError("Couldn't create cell of type PVGameLibraryCollectionViewCellIdentifier")
        }

        let game = self.game(at: indexPath, location: .zero)
        cell.game = game
        cell.delegate = self

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let viewModel: GameLibrarySectionViewModel
            let headerView = (collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                              withReuseIdentifier: PVGameLibraryHeaderViewIdentifier,
                                                                              for: indexPath) as? PVGameLibrarySectionHeaderView)!
            if searchResults != nil {
                viewModel = GameLibrarySectionViewModel(title: "Search Results", collapsable: false, collapsed: false)
            } else {
                let title = sectionTitles[indexPath.section]

                if indexPath.section >= systemsSectionOffset, let systemIdentifier = filteredSystems?[indexPath.section - systemsSectionOffset].identifier {
                    if let token = self.systemSectionsTokens[systemIdentifier] {
                        viewModel = GameLibrarySectionViewModel(title: title, collapsable: true, collapsed: token.viewModel.collapsed)
                    } else {
                        viewModel = GameLibrarySectionViewModel(title: title, collapsable: true, collapsed: false)
                    }
                    #if canImport(RxGesture)
                        headerView.collapseImageView.rx.tapGesture()
                            .when(.recognized)
                            .subscribe(onNext: { _ in
                                if let token = self.systemSectionsTokens[systemIdentifier] {
                                    let collapsed = !token.viewModel.collapsed
                                    token.viewModel.collapsed = collapsed
                                    if collapsed {
                                        PVSettingsModel.shared.collapsedSystems.insert(systemIdentifier)
                                    } else {
                                        PVSettingsModel.shared.collapsedSystems.remove(systemIdentifier)
                                    }
                                    collectionView.reloadSections([indexPath.section])
                                } else {
                                    ELOG("systemSectionsTokens was missing entry for key <\(systemIdentifier)>")
                                }
                            })
                            .disposed(by: headerView.disposeBag)
                    #endif
                } else {
                    viewModel = GameLibrarySectionViewModel(title: title, collapsable: false, collapsed: false)
                }
            }

            headerView.viewModel = viewModel

            return headerView
        } else if kind == UICollectionView.elementKindSectionFooter {
            let footerView = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PVGameLibraryFooterViewIdentifier, for: indexPath) as! PVGameLibrarySectionFooterView
            return footerView
        }

        fatalError("Don't support type \(kind)")
    }
}
// MARK: - UICollectionViewDelegate

extension PVGameLibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //		if searchResults == nil, indexPath.section == saveStateSection {
        //			let cell = collectionView.cellForItem(at: indexPath)
        //			let saveState = saveStates![indexPath.row]
        //			load(saveState.game, sender: cell, core: saveState.core, saveState: saveState)
        //		} else {
        if let game = self.game(at: indexPath, location: .zero) {
            let cell = collectionView.cellForItem(at: indexPath)
            load(game, sender: cell, core: nil)
        } else {
            let alert = UIAlertController(title: "Failed to find game", message: "No game found for selected cell", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
        }
        //		}
    }
}

// MARK: - CollectionView helpers

extension PVGameLibraryViewController {
    func game(at indexPath: IndexPath, location: CGPoint) -> PVGame? {
        var game: PVGame?
        if let searchResults = searchResults {
            game = Array(searchResults)[indexPath.item]
        } else {
            let section = indexPath.section
            let row = indexPath.row

            if section == favoritesSection {
                let favoritesCell = collectionView!.cellForItem(at: IndexPath(row: 0, section: favoritesSection)) as! FavoritesPlayedCollectionCell

                let location2 = favoritesCell.internalCollectionView.convert(location, from: collectionView)
                let indexPath2 = favoritesCell.internalCollectionView.indexPathForItem(at: location2)!

                if let favoriteGames = favoriteGames, favoriteGames.count > indexPath2.row {
                    game = favoriteGames[indexPath2.row]
                } else {
                    ELOG("row \(row) out of bounds for favoriteGames count \(favoriteGames?.count ?? -1)")
                }
            } else if section == recentGamesSection {
                let recentlyPlayedCell = collectionView!.cellForItem(at: IndexPath(row: 0, section: recentGamesSection)) as! RecentlyPlayedCollectionCell

                let location2 = recentlyPlayedCell.internalCollectionView.convert(location, from: collectionView)
                guard let indexPath2 = recentlyPlayedCell.internalCollectionView.indexPathForItem(at: location2) else {
                    return nil
                }

                if let recentGames = recentGames, recentGames.count > indexPath2.row {
                    game = recentGames[indexPath2.row].game
                } else {
                    ELOG("row \(row) out of bounds for recentGame count \(recentGames?.count ?? -1)")
                }
            } else if section == saveStateSection {
                if let saveStates = saveStates, saveStates.count > row {
                    game = saveStates[row].game
                } else {
                    ELOG("row \(row) out of bounds for saveStates count \(saveStates?.count ?? -1)")
                }
            } else if let system = filteredSystems?[section - systemsSectionOffset] {
                game = systemSectionsTokens[system.identifier]?.query[row]
            } else {
                ELOG("Unknown section \(section)")
            }
        }

        return game
    }
}
*/
