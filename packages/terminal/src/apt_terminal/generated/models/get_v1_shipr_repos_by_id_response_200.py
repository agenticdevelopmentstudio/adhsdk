from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_dev_repo import ShiprDevRepo
    from ..models.shipr_group import ShiprGroup
    from ..models.shipr_ladder import ShiprLadder
    from ..models.shipr_repo import ShiprRepo
    from ..models.shipr_run import ShiprRun


T = TypeVar("T", bound="GetV1ShiprReposByIdResponse200")


@_attrs_define
class GetV1ShiprReposByIdResponse200:
    """
    Attributes:
        object_ (Literal['shipr.repo'] | Unset):
        repo (ShiprRepo | Unset): One deployment repository — a mirror. A dev repo with several `[deployments]` shards
            has one of these per shard.
        dev_repo (None | ShiprDevRepo | Unset):
        group (None | ShiprGroup | Unset):
        ladder (None | ShiprLadder | Unset):
        runs (list[ShiprRun] | Unset):
    """

    object_: Literal["shipr.repo"] | Unset = UNSET
    repo: ShiprRepo | Unset = UNSET
    dev_repo: None | ShiprDevRepo | Unset = UNSET
    group: None | ShiprGroup | Unset = UNSET
    ladder: None | ShiprLadder | Unset = UNSET
    runs: list[ShiprRun] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.shipr_dev_repo import ShiprDevRepo
        from ..models.shipr_group import ShiprGroup
        from ..models.shipr_ladder import ShiprLadder

        object_ = self.object_

        repo: dict[str, Any] | Unset = UNSET
        if not isinstance(self.repo, Unset):
            repo = self.repo.to_dict()

        dev_repo: dict[str, Any] | None | Unset
        if isinstance(self.dev_repo, Unset):
            dev_repo = UNSET
        elif isinstance(self.dev_repo, ShiprDevRepo):
            dev_repo = self.dev_repo.to_dict()
        else:
            dev_repo = self.dev_repo

        group: dict[str, Any] | None | Unset
        if isinstance(self.group, Unset):
            group = UNSET
        elif isinstance(self.group, ShiprGroup):
            group = self.group.to_dict()
        else:
            group = self.group

        ladder: dict[str, Any] | None | Unset
        if isinstance(self.ladder, Unset):
            ladder = UNSET
        elif isinstance(self.ladder, ShiprLadder):
            ladder = self.ladder.to_dict()
        else:
            ladder = self.ladder

        runs: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.runs, Unset):
            runs = []
            for runs_item_data in self.runs:
                runs_item = runs_item_data.to_dict()
                runs.append(runs_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_
        if repo is not UNSET:
            field_dict["repo"] = repo
        if dev_repo is not UNSET:
            field_dict["dev_repo"] = dev_repo
        if group is not UNSET:
            field_dict["group"] = group
        if ladder is not UNSET:
            field_dict["ladder"] = ladder
        if runs is not UNSET:
            field_dict["runs"] = runs

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_dev_repo import ShiprDevRepo
        from ..models.shipr_group import ShiprGroup
        from ..models.shipr_ladder import ShiprLadder
        from ..models.shipr_repo import ShiprRepo
        from ..models.shipr_run import ShiprRun

        d = dict(src_dict)
        object_ = cast(Literal["shipr.repo"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.repo" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.repo', got '{object_}'")

        _repo = d.pop("repo", UNSET)
        repo: ShiprRepo | Unset
        if isinstance(_repo, Unset):
            repo = UNSET
        else:
            repo = ShiprRepo.from_dict(_repo)

        def _parse_dev_repo(data: object) -> None | ShiprDevRepo | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                dev_repo_type_0 = ShiprDevRepo.from_dict(data)

                return dev_repo_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ShiprDevRepo | Unset, data)

        dev_repo = _parse_dev_repo(d.pop("dev_repo", UNSET))

        def _parse_group(data: object) -> None | ShiprGroup | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                group_type_0 = ShiprGroup.from_dict(data)

                return group_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ShiprGroup | Unset, data)

        group = _parse_group(d.pop("group", UNSET))

        def _parse_ladder(data: object) -> None | ShiprLadder | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                ladder_type_0 = ShiprLadder.from_dict(data)

                return ladder_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ShiprLadder | Unset, data)

        ladder = _parse_ladder(d.pop("ladder", UNSET))

        _runs = d.pop("runs", UNSET)
        runs: list[ShiprRun] | Unset = UNSET
        if _runs is not UNSET:
            runs = []
            for runs_item_data in _runs:
                runs_item = ShiprRun.from_dict(runs_item_data)

                runs.append(runs_item)

        get_v1_shipr_repos_by_id_response_200 = cls(
            object_=object_,
            repo=repo,
            dev_repo=dev_repo,
            group=group,
            ladder=ladder,
            runs=runs,
        )

        get_v1_shipr_repos_by_id_response_200.additional_properties = d
        return get_v1_shipr_repos_by_id_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
