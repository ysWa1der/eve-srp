<?php

declare(strict_types=1);

namespace EveSrp\Provider\Implementation;

use EveSrp\Provider\ProviderInterface;
use EveSrp\Provider\Data\Account;
use EveSrp\Service\ApiService;
use EveSrp\Settings;

/**
 * A very simple group and character provider.
 *
 * Groups are assigned based on alliance and/or corporation membership or character IDs.
 *
 * This does not support alternative characters.
 */
class EsiProvider implements ProviderInterface
{
    private string $esiBaseUrl;

    public function __construct(private readonly ApiService $apiService, Settings $settings)
    {
        $this->esiBaseUrl = $settings['URLs']['esi'];
    }

    public function getAccount(int $eveCharacterId): ?Account
    {
        return null;
    }

    public function getGroups(int $eveCharacterId): array
    {
        $userData = $this->apiService->getJsonData("$this->esiBaseUrl/characters/$eveCharacterId/");

        // Helper function to parse comma-separated IDs
        $parseIds = function(string $value): array {
            $trimmed = trim($value);
            if ($trimmed === '') {
                return [];
            }
            return array_filter(array_map('trim', explode(',', $trimmed)), function($v) {
                return $v !== '';
            });
        };

        $submitterAlliances = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_SUBMITTER_ALLIANCES'] ?? ''));
        $submitterCorporations = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_SUBMITTER_CORPORATIONS'] ?? ''));
        $reviewChars = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_REVIEW_CHARACTERS'] ?? ''));
        $reviewCorps = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_REVIEW_CORPORATIONS'] ?? ''));
        $payChars = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_PAY_CHARACTERS'] ?? ''));
        $payCorps = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_PAY_CORPORATIONS'] ?? ''));
        $adminChars = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_ADMIN_CHARACTERS'] ?? ''));
        $globalAdminChars = $parseIds((string)($_ENV['EVE_SRP_PROVIDER_ESI_GLOBAL_ADMIN_CHARACTERS'] ?? ''));

        $groups = [];

        // Check submitter (member) group
        $hasAllianceMatch = isset($userData->alliance_id) && in_array((string)$userData->alliance_id, $submitterAlliances, true);
        $hasCorpMatch = isset($userData->corporation_id) && in_array((string)$userData->corporation_id, $submitterCorporations, true);
        if ($hasAllianceMatch || $hasCorpMatch) {
            $groups[] = 'member';
        }

        // Check review group
        if (in_array((string)$eveCharacterId, $reviewChars, true) ||
            (isset($userData->corporation_id) && in_array((string)$userData->corporation_id, $reviewCorps, true))) {
            $groups[] = 'review';
        }

        // Check pay group
        if (in_array((string)$eveCharacterId, $payChars, true) ||
            (isset($userData->corporation_id) && in_array((string)$userData->corporation_id, $payCorps, true))) {
            $groups[] = 'pay';
        }

        // Check admin group
        if (in_array((string)$eveCharacterId, $adminChars, true)) {
            $groups[] = 'admin';
        }

        // Check global admin group
        if (in_array((string)$eveCharacterId, $globalAdminChars, true)) {
            $groups[] = 'global-admin';
        }

        return $groups;
    }

    public function getAvailableGroups(): array
    {
        return ['member', 'review', 'pay', 'admin', 'global-admin'];
    }
}
